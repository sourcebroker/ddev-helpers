## Getting started

### project-audit

Runs `composer audit` for the project and turns it into a short, actionable list.

```
ddev project-audit
```

```
my-project  TYPO3 v11.5.41  (no ELTS)

  ✗ high     symfony/http-kernel              v5.4.31      update to 5.4.46
  ✗ medium   guzzlehttp/guzzle                7.4.0        update to 7.4.5
  • deferred 4 typo3/cms-* packages  already at the highest public release (11.5.41); the fix (11.5.42) is only in paid ELTS, which this project has not bought
      (-v to list them)

  2 abandoned package(s): doctrine/annotations, swiftmailer/swiftmailer
  2 package(s) to update
```

What it adds over plain `composer audit`:

* It names the release to update to. Composer prints the affected range
  (`>=8.0.0,<8.0.1|<7.15.2`) and leaves you to work out which version on *your*
  branch closes it.
* It applies TYPO3's ELTS ceiling. `composer audit` keeps reporting `typo3/cms-*`
  as vulnerable even when the project is already on the highest public release,
  because the fix shipped only in the paid ELTS subscription. Those packages are
  reported as deferred with `nothing to install`, so the list you see is work you
  can actually do.
* The `typo3/cms-*` packages collapse into one line. Use `-v` to list them.

The first run in a TYPO3 project asks once whether the project has bought ELTS
and remembers the answer in `.ddev/.typo3-audit.sb.json`. Delete that file to be
asked again, or pass `--elts` / `--no-elts`. A non-interactive run assumes no
subscription.

Useful flags:

| Flag                   | Effect                                                 |
|------------------------|--------------------------------------------------------|
| `-v`                   | list every deferred package instead of collapsing them |
| `--json`               | print the verdict as JSON                              |
| `--no-dev`, `--locked` | passed through to `composer audit`                     |
| `--fail-on-findings`   | exit 1 when packages need updating, for CI             |

The command exits 0 by default even when it finds work, so DDEV does not append
a misleading `Failed to run`; exit 2 means the audit could not be determined
(no `composer.json`, or Composer produced no output).

It works on any Composer project — the ELTS part simply does not apply when
`typo3/cms-core` is not installed. TYPO3 release data comes from
`https://get.typo3.org`, which needs to be reachable from the web container;
only the major version number is sent. Nothing else about the project leaves the
machine.
