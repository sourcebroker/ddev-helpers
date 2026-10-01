#!/usr/bin/env bash
#sb-generated

## Description: [BASE] Install Claude Code plugins enabled in .claude/settings.json that are missing locally
## Usage: claude-plugins [--scope project|local] [--force]
## Example: "ddev claude-plugins" or "ddev claude-plugins --force"

TEXT_GREEN=$(tput setaf 2 2>/dev/null)
TEXT_YELLOW=$(tput setaf 3 2>/dev/null)
TEXT_RED=$(tput setaf 1 2>/dev/null)
TEXT_RESET=$(tput sgr0 2>/dev/null)

scope="project"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) scope="$2"; shift 2 ;;
    --scope=*) scope="${1#--scope=}"; shift ;;
    --force) force=1; shift ;;
    -h|--help)
      echo "Usage: ddev claude-plugins [--scope project|local] [--force]"
      echo ""
      echo "Reads enabledPlugins and extraKnownMarketplaces from .claude/settings.json,"
      echo "adds missing marketplaces and installs plugins not yet installed for this project."
      echo "  --force  reinstall every enabled plugin"
      exit 0
      ;;
    *) echo "${TEXT_RED}Unknown option: $1${TEXT_RESET}" >&2; exit 1 ;;
  esac
done

cd "${DDEV_APPROOT:-.}" || exit 1
projectPath="$(pwd)"
settings=".claude/settings.json"

for bin in jq claude; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "${TEXT_RED}'$bin' is required but not installed on the host${TEXT_RESET}" >&2
    exit 1
  fi
done

if [[ ! -f "$settings" ]]; then
  echo "${TEXT_RED}$settings not found${TEXT_RESET}" >&2
  exit 1
fi

pluginsDir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins"
knownMarketplaces="$pluginsDir/known_marketplaces.json"
installedPlugins="$pluginsDir/installed_plugins.json"

# Marketplaces from extraKnownMarketplaces that are not known locally yet
while IFS=$'\t' read -r name source; do
  [[ -z "$name" ]] && continue
  if [[ -f "$knownMarketplaces" ]] && jq -e --arg n "$name" 'has($n)' "$knownMarketplaces" >/dev/null 2>&1; then
    continue
  fi
  echo "${TEXT_GREEN}Adding marketplace $name${TEXT_RESET}"
  claude plugin marketplace add "$source" || echo "${TEXT_RED}Failed to add marketplace $name${TEXT_RESET}"
done < <(jq -r '(.extraKnownMarketplaces // {}) | to_entries[]
  | [.key, (.value.source | if .source == "github" then .repo else (.url // .path) end)] | @tsv' "$settings")

isInstalled() {
  [[ -f "$installedPlugins" ]] || return 1
  jq -e --arg p "$1" --arg path "$projectPath" '
    (.plugins[$p] // []) | any(.scope == "user" or .projectPath == $path)' "$installedPlugins" >/dev/null 2>&1
}

installed=0
skipped=0
failed=0

while IFS= read -r plugin; do
  [[ -z "$plugin" ]] && continue
  if [[ $force == 0 ]] && isInstalled "$plugin"; then
    skipped=$((skipped + 1))
    continue
  fi
  echo "${TEXT_GREEN}Installing $plugin (--scope $scope)${TEXT_RESET}"
  if claude plugin install "$plugin" --scope "$scope"; then
    installed=$((installed + 1))
  else
    failed=$((failed + 1))
    echo "${TEXT_RED}Failed to install $plugin${TEXT_RESET}"
  fi
done < <(jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value == true) | .key' "$settings")

echo ""
echo "Installed: $installed, already installed: $skipped, failed: $failed"
if [[ $installed -gt 0 ]]; then
  echo "${TEXT_YELLOW}Run /reload-plugins in Claude Code (or restart it) to apply.${TEXT_RESET}"
fi
[[ $failed -eq 0 ]]
