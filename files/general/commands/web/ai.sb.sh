#!/bin/bash

## Description: Manage AI agent tooling. Commands: init, update, sync, rules-list, skill list, skill read-skill, clean
## Usage: ai <command> [args] [--force]
## Example: "ddev ai init"

set -euo pipefail

TOOLING_DIR="/var/www/html/.agents-tooling"
CMD="${1:-}"
SUBCMD="${2:-}"
FORCE_PARAM=""
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE_PARAM="?force=1"
done

case "$CMD" in
  init)
    _ERR=0
    if [ -z "${AGENT_INSTALL_USER:-}" ]; then
      echo "Error: AGENT_INSTALL_USER is not set in the environment." >&2
      _ERR=1
    fi
    if [ -z "${AGENT_INSTALL_PASS:-}" ]; then
      echo "Error: AGENT_INSTALL_PASS is not set in the environment." >&2
      _ERR=1
    fi
    [ "$_ERR" -eq 1 ] && exit 1
    curl -fLs --user "${AGENT_INSTALL_USER}:${AGENT_INSTALL_PASS}" "https://agents.inscript.pl/install/${FORCE_PARAM}" | bash
    ;;
  update|sync|rules-list|skill)
    if [ ! -d "$TOOLING_DIR" ]; then
      echo "Error: $TOOLING_DIR does not exist. Run 'ddev ai init' first." >&2
      exit 1
    fi
    cd "$TOOLING_DIR"
    case "$CMD" in
      update)
        composer update
        ;;
      sync)
        composer sync-rules
#        composer sync-skills
        ;;
      rules-list)
        composer list-rules
        ;;
      skill)
        case "$SUBCMD" in
          list)
            composer list-skills
            ;;
          read)
            skill_name="${3:-}"
            if [ -z "$skill_name" ]; then
              echo "Error: Missing skill name. Usage: ddev ai skill read-skill <skill-name>" >&2
              exit 1
            fi
            composer read-skill "$skill_name"
            ;;
          *)
            echo "Usage: ddev ai skill <list|read <skill-name>>" >&2
            exit 1
            ;;
        esac
        ;;
    esac
    ;;
  clean)
    PROJECT_ROOT="/var/www/html"
    CLEANUP_DIR="$TOOLING_DIR/cleanup"
    DIRS_TO_CHECK=""
    if [ -d "$CLEANUP_DIR" ]; then
      for manifest in "$CLEANUP_DIR"/*.txt; do
        [ -f "$manifest" ] || continue
        while IFS= read -r path || [ -n "$path" ]; do
          [ -z "$path" ] && continue
          target="$PROJECT_ROOT/$path"
          if [ -f "$target" ] || [ -L "$target" ]; then
            rm -f "$target"
            DIRS_TO_CHECK="$DIRS_TO_CHECK $PROJECT_ROOT/$(dirname "$path")"
          fi
        done < "$manifest"
      done
    fi
    # Remove empty directories derived from manifest paths
    if [ -n "$DIRS_TO_CHECK" ]; then
      echo "$DIRS_TO_CHECK" | tr ' ' '\n' | sort -ru | while read -r dir; do
        [ -d "$dir" ] && find "$dir" -mindepth 0 -type d -empty -delete 2>/dev/null || true
      done
    fi
    rm -rf "$TOOLING_DIR"
    echo "AI tooling cleaned up. Run 'ddev ai init' to start fresh."
    ;;
  *)
    echo "Usage: ddev ai <command>"
    echo ""
    echo "Commands:"
    echo "  init                      Install AI agent tooling"
    echo "  update                    Update packages and sync all AI tooling"
    echo "  sync                      Manually sync rules without updating packages"
    echo "  clean                     Remove all generated AI files and tooling"
    echo "  rules-list                List installed agent-rules packages"
    echo "  skill list                List installed AI skills"
    echo "  skill read <skill-name>   Read a specific AI skill"
    exit 1
    ;;
esac

