#!/usr/bin/env python3
#sb-generated

## Description: Audit this project's Composer packages, judging TYPO3 against its public release ceiling
## Usage: project-audit [flags]
## Example: "ddev project-audit", "ddev project-audit -v", "ddev project-audit --elts", "ddev project-audit --json"

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Sequence

API_ROOT = "https://get.typo3.org/api/v1"
ELTS_ANSWER_FILE = ".ddev/.typo3-audit.sb.json"

EXIT_OK = 0
EXIT_ACTION = 1
EXIT_UNKNOWN = 2

ACTION = "action"
DEFERRED = "deferred"

SEVERITY_RANK = {"critical": 0, "high": 1, "medium": 2, "moderate": 2, "low": 3, "unrated": 4}
_COLOURS = {"critical": "\033[31;1m", "high": "\033[31m", "medium": "\033[33m", "low": "\033[2m"}
_RESET, _DIM, _GREEN = "\033[0m", "\033[2m", "\033[32m"

_PRERELEASE = {"dev": -4, "alpha": -3, "a": -3, "beta": -2, "b": -2, "rc": -1, "pl": 1, "p": 1}
_UNORDERABLE = re.compile(r"(^dev-)|(\.x-dev$)", re.IGNORECASE)
# Alternatives split by `|`, each a comma-joined AND-range:
# `<10.4.57|>=11.0.0,<11.5.51|>=12.0.0,<12.4.46`.
_CONSTRAINT = re.compile(r"(?P<operator><=|>=|<|>|==|=)?\s*(?P<version>[0-9][^\s,|]*)")


def parse_version(text: str) -> tuple | None:
    """Order a Composer version string, or None when it has no order."""
    if not text:
        return None
    value = str(text).strip()
    if _UNORDERABLE.search(value):
        return None
    value = value.lstrip("vV")
    match = re.match(r"^(\d+(?:\.\d+)*)(?:[.\-+]?([A-Za-z]+)\.?(\d*))?", value)
    if not match:
        return None
    numbers = ([int(part) for part in match.group(1).split(".")] + [0, 0, 0])[:4]
    label = (match.group(2) or "").lower()
    if not label:
        return (tuple(numbers), 0, 0)
    rank = _PRERELEASE.get(label)
    if rank is None:
        return (tuple(numbers), 0, 0)
    return (tuple(numbers), rank, int(match.group(3) or 0))


def severity_rank(severity: str) -> int:
    return SEVERITY_RANK.get((severity or "unrated").lower(), SEVERITY_RANK["unrated"])


def worst_severity(values: Iterable[str]) -> str:
    ranked = sorted((value or "unrated").lower() for value in values)
    return min(ranked, key=severity_rank) if ranked else "unrated"


def is_typo3_core(package: str) -> bool:
    return package.startswith("typo3/cms-") or package == "typo3/cms"


def _get(url: str) -> Any:
    request = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read())


def typo3_release_data(major: int) -> dict | None:
    """Public ceiling, ELTS head and maintenance dates for one TYPO3 major."""
    try:
        majors = {int(float(entry["version"])): entry for entry in _get(f"{API_ROOT}/major/")}
        entry = majors.get(major)
        if entry is None:
            return None
        releases = _get(f"{API_ROOT}/major/{entry['version']}/release/")
    except (urllib.error.URLError, TimeoutError, OSError, ValueError, KeyError):
        return None

    def highest(items: Iterable[str]) -> str:
        ordered = sorted((v for v in items if parse_version(v)), key=parse_version)
        return ordered[-1] if ordered else ""

    return {
        "major": major,
        "maintained_until": str(entry.get("maintained_until") or ""),
        "elts_until": str(entry.get("elts_until") or ""),
        "latest_free": highest(r.get("version", "") for r in releases if not r.get("elts")),
        "latest_elts": highest(r.get("version", "") for r in releases if r.get("elts")),
    }


def is_end_of_life(release_data: dict) -> bool:
    try:
        return datetime.now(timezone.utc).date() >= datetime.fromisoformat(
            release_data["elts_until"]
        ).date()
    except (ValueError, KeyError):
        return False


@dataclass
class PackageResult:
    name: str
    version: str
    advisories: int
    severity: str
    status: str
    action: str
    note: str = ""

    @property
    def sort_key(self) -> tuple:
        return (0 if self.status == ACTION else 1, severity_rank(self.severity), self.name)


@dataclass
class ProjectAudit:
    project: str = ""
    typo3_version: str = ""
    elts: bool = False
    results: list[PackageResult] = field(default_factory=list)
    abandoned: list[str] = field(default_factory=list)

    @property
    def actionable(self) -> list[PackageResult]:
        return [item for item in self.results if item.status == ACTION]

    @property
    def deferred(self) -> list[PackageResult]:
        return [item for item in self.results if item.status == DEFERRED]

    @property
    def clean(self) -> bool:
        return not self.actionable


def branch_fix(affected: str, installed: tuple | None) -> tuple[str, bool]:
    """The release closing the affected branch that contains `installed`.

    Returns ``(version, exact)``; ``exact`` is False for a `<=` bound, which says
    the fix is above that release without naming it.
    """
    if installed is None:
        return "", True
    for alternative in str(affected or "").split("|"):
        bound, exact, contains = "", True, True
        for match in _CONSTRAINT.finditer(alternative):
            version = parse_version(match.group("version"))
            if version is None:
                continue
            operator = match.group("operator") or "=="
            if operator == ">=" and installed < version:
                contains = False
            elif operator == ">" and installed <= version:
                contains = False
            elif operator == "<":
                if installed >= version:
                    contains = False
                bound, exact = match.group("version"), True
            elif operator == "<=":
                if installed > version:
                    contains = False
                bound, exact = match.group("version"), False
            elif operator in ("==", "=") and installed != version:
                contains = False
        if contains and bound:
            return bound, exact
    return "", True


def fix_for(advisories: Sequence[dict], installed: str) -> tuple[str, bool]:
    current = parse_version(installed)
    best: tuple | None = None
    exact = True
    for advisory in advisories:
        bound, is_exact = branch_fix(str(advisory.get("affectedVersions") or ""), current)
        parsed = parse_version(bound) if bound else None
        if parsed and (best is None or parsed > best[0]):
            best, exact = (parsed, bound), is_exact
    return (best[1], exact) if best else ("", True)


def phrase(fix: str, exact: bool) -> str:
    if not fix:
        return "no fixed release published"
    return f"update to {fix}" if exact else f"update past {fix}"


def core_result(
    name: str, version: str, advisories: Sequence[dict], *, elts: bool, releases: dict | None
) -> PackageResult:
    severity = worst_severity(str(item.get("severity") or "") for item in advisories)
    fix, exact = fix_for(advisories, version)
    count = len(advisories)

    if not releases:
        return PackageResult(
            name, version, count, severity, ACTION, phrase(fix, exact),
            note="no TYPO3 release data (get.typo3.org unreachable)",
        )
    if is_end_of_life(releases):
        return PackageResult(
            name, version, count, severity, ACTION, "major upgrade",
            note=f"TYPO3 {releases['major']} is end of life — even paid ELTS ended "
            f"{releases['elts_until'][:10]}",
        )
    if elts:
        head = releases.get("latest_elts") or "the ELTS head"
        return PackageResult(
            name, version, count, severity, ACTION, phrase(fix, exact) if fix else f"update to {head}",
            note="this project has bought ELTS",
        )

    ceiling = releases.get("latest_free") or ""
    installed, limit = parse_version(version), parse_version(ceiling)
    if installed and limit and installed < limit:
        return PackageResult(
            name, version, count, severity, ACTION, f"update to {ceiling}",
            note=f"the highest public release of TYPO3 {releases['major']}",
        )
    if installed and limit:
        named = (
            f"the fix ({fix}) is only in paid ELTS" if fix and exact
            else "the fix is only in paid ELTS"
        )
        return PackageResult(
            name, version, count, severity, DEFERRED, "nothing to install",
            note=f"already at the highest public release ({ceiling}); {named}, "
            "which this project has not bought",
        )
    return PackageResult(name, version, count, severity, ACTION, phrase(fix, exact))


def classify(
    audit: dict[str, Any],
    versions: dict[str, str],
    releases: dict | None,
    *,
    project: str = "",
    elts: bool = False,
) -> ProjectAudit:
    """Turn `composer audit --format=json` into a verdict per package."""
    report = ProjectAudit(
        project=project,
        typo3_version=versions.get("typo3/cms-core", ""),
        elts=elts,
        abandoned=sorted((audit.get("abandoned") or {}).keys()),
    )
    for name, advisories in (audit.get("advisories") or {}).items():
        advisories = list(advisories or [])
        version = versions.get(name, "")
        if is_typo3_core(name):
            report.results.append(
                core_result(name, version, advisories, elts=elts, releases=releases)
            )
            continue
        severity = worst_severity(str(item.get("severity") or "") for item in advisories)
        fix, exact = fix_for(advisories, version)
        report.results.append(
            PackageResult(name, version, len(advisories), severity, ACTION, phrase(fix, exact))
        )
    report.results.sort(key=lambda item: item.sort_key)
    return report


def installed_versions(project: Path) -> dict[str, str]:
    """What the project has, from the installed metadata or else the lock."""
    installed = project / "vendor" / "composer" / "installed.json"
    if installed.exists():
        data = json.loads(installed.read_text(encoding="utf-8"))
        packages = data.get("packages", data) if isinstance(data, dict) else data
        return {item["name"]: str(item.get("version", "")) for item in packages if item.get("name")}
    lock = project / "composer.lock"
    if lock.exists():
        data = json.loads(lock.read_text(encoding="utf-8"))
        return {
            item["name"]: str(item.get("version", ""))
            for item in data.get("packages", []) + data.get("packages-dev", [])
            if item.get("name")
        }
    return {}


def project_name(project: Path) -> str:
    """What to call this project — inside the container every directory is "html"."""
    return os.environ.get("DDEV_SITENAME") or project.name


def in_ddev_container() -> bool:
    return os.environ.get("IS_DDEV_PROJECT") == "true" or Path("/mnt/ddev_config").is_dir()


def run_composer_audit(project: Path, flags: Sequence[str]) -> dict | None:
    """Ask Composer for its audit, wherever this happens to be running.

    The `|| true` matters: ddev discards stdout when a command exits non-zero,
    and `composer audit` exits 1 whenever it finds anything.
    """
    joined = " ".join(["composer", "audit", "--format=json", *flags])
    if in_ddev_container():
        attempt = ["sh", "-c", f"{joined} || true"]
    elif (project / ".ddev").is_dir() and shutil.which("ddev"):
        attempt = ["ddev", "exec", f"{joined} || true"]
    elif shutil.which("composer"):
        attempt = ["sh", "-c", f"{joined} || true"]
    else:
        print("project audit: no composer and no ddev to run it in", file=sys.stderr)
        return None

    try:
        result = subprocess.run(attempt, cwd=project, capture_output=True, text=True)
    except OSError as error:
        print(f"project audit: could not run composer: {error}", file=sys.stderr)
        return None

    start = result.stdout.find("{")
    if start == -1:
        print("project audit: composer audit produced no JSON", file=sys.stderr)
        if result.stderr.strip():
            print(result.stderr.strip()[:400], file=sys.stderr)
        return None
    try:
        return json.loads(result.stdout[start:])
    except json.JSONDecodeError as error:
        print(f"project audit: could not read composer's answer: {error}", file=sys.stderr)
        return None


def resolve_elts(project: Path, chosen: bool | None) -> bool:
    """Has this project bought TYPO3 ELTS?

    Remembered per project, so the question is asked once; a non-interactive run
    assumes no subscription.
    """
    if chosen is not None:
        return chosen

    answer_file = project / ELTS_ANSWER_FILE
    try:
        remembered = json.loads(answer_file.read_text(encoding="utf-8"))
        if isinstance(remembered.get("elts"), bool):
            return remembered["elts"]
    except (OSError, json.JSONDecodeError, AttributeError):
        pass

    if not sys.stdin.isatty():
        return False

    print("TYPO3 ELTS is a paid subscription for versions past their free maintenance.")
    reply = input(f"Has {project_name(project)} bought ELTS? [y/N] ").strip().lower()
    elts = reply in ("y", "yes")
    try:
        answer_file.parent.mkdir(parents=True, exist_ok=True)
        answer_file.write_text(json.dumps({"elts": elts}) + "\n", encoding="utf-8")
        print(f"remembered in {ELTS_ANSWER_FILE} — delete it to be asked again, "
              "or use --elts/--no-elts\n")
    except OSError:
        pass
    return elts


def colour(text: str, code: str) -> str:
    return f"{code}{text}{_RESET}" if sys.stdout.isatty() else text


def render(report: ProjectAudit, *, verbose: bool) -> None:
    header = f"{report.project}"
    if report.typo3_version:
        header += f"  TYPO3 {report.typo3_version}"
        header += "  (ELTS bought)" if report.elts else "  (no ELTS)"
    print(header)
    print()

    if not report.results:
        print(colour("  nothing reported by composer audit", _GREEN))

    shown = report.results
    if not verbose and len(report.deferred) > 1:
        # The core moves as one package set; listing every `typo3/cms-*` buries
        # the rows that are actually work.
        shown = report.actionable
    for item in shown:
        mark = colour("✗", _COLOURS.get(item.severity, "")) if item.status == ACTION else "•"
        severity = colour(f"{item.severity:8}", _COLOURS.get(item.severity, _DIM))
        line = f"  {mark} {severity} {item.name:32} {item.version:12} {item.action}"
        print(colour(line, _DIM) if item.status == DEFERRED else line)
        if item.note:
            print(colour(f"      {item.note}", _DIM))

    if shown is not report.results and report.deferred:
        print(colour(
            f"  • {'deferred':8} {len(report.deferred)} typo3/cms-* packages  "
            f"{report.deferred[0].note}",
            _DIM,
        ))
        print(colour("      (-v to list them)", _DIM))

    print()
    if report.abandoned:
        print(colour(
            f"  {len(report.abandoned)} abandoned package(s): "
            + ", ".join(report.abandoned[:5]),
            _DIM,
        ))
    if report.clean:
        message = "nothing left to update"
        if report.deferred:
            message += f" ({len(report.deferred)} TYPO3 core package(s) deferred — paid ELTS only)"
        print(colour(f"  {message}", _GREEN))
    else:
        print(colour(f"  {len(report.actionable)} package(s) to update", _COLOURS["high"]))


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="project-audit",
        description="Check one project's composer audit, with TYPO3's ELTS ceiling applied.",
    )
    parser.add_argument(
        "project",
        nargs="?",
        default=".",
        help="project directory, or '-' to read composer audit --format=json from stdin",
    )
    parser.add_argument("--no-dev", action="store_true", help="pass --no-dev to composer audit")
    parser.add_argument("--locked", action="store_true", help="pass --locked to composer audit")
    parser.add_argument(
        "--elts",
        action=argparse.BooleanOptionalAction,
        default=None,
        help="whether this project has bought TYPO3 ELTS (otherwise you are asked once)",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="list every deferred package")
    parser.add_argument("--json", action="store_true", help="print the verdict as JSON")
    parser.add_argument(
        "--fail-on-findings",
        action="store_true",
        help=(
            "exit 1 when packages need updating (useful in CI); by default findings are "
            "reported without failing the command"
        ),
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = parse_args(argv)
    if arguments.project == "-":
        project = Path.cwd()
        try:
            audit = json.load(sys.stdin)
        except json.JSONDecodeError as error:
            print(f"project audit: stdin is not composer audit JSON: {error}", file=sys.stderr)
            return EXIT_UNKNOWN
    else:
        project = Path(arguments.project).expanduser().resolve()
        if not (project / "composer.json").exists():
            print(f"project audit: no composer.json in {project}", file=sys.stderr)
            return EXIT_UNKNOWN
        flags = [flag for flag, on in (("--no-dev", arguments.no_dev),
                                       ("--locked", arguments.locked)) if on]
        audit = run_composer_audit(project, flags)
        if audit is None:
            return EXIT_UNKNOWN

    versions = installed_versions(project)
    core = versions.get("typo3/cms-core", "")
    parsed = parse_version(core)
    elts = resolve_elts(project, arguments.elts) if parsed else False
    releases = typo3_release_data(parsed[0][0]) if parsed else None

    report = classify(audit, versions, releases, project=project_name(project), elts=elts)

    if arguments.json:
        print(json.dumps({
            "project": report.project,
            "typo3": report.typo3_version,
            "elts": report.elts,
            "clean": report.clean,
            "packages": [vars(item) for item in report.results],
            "abandoned": report.abandoned,
        }, indent=2))
    else:
        render(report, verbose=arguments.verbose)

    if arguments.fail_on_findings and not report.clean:
        return EXIT_ACTION
    return EXIT_OK


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(EXIT_UNKNOWN)
