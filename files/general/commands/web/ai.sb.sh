#!/bin/bash

## Description: Manage AI agent tooling. Commands: init, update, sync, rules-list
## Usage: ai <command> [--force]
## Example: "ddev ai init"

set -euo pipefail

TOOLING_DIR="/var/www/html/.agents-tooling"
CMD="${1:-}"
FORCE_PARAM=""
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE_PARAM="?force=1"
done

case "$CMD" in
  init)
    ENV_FILE="/var/www/html/.env"
    if [ -z "${AGENT_INSTALL_USER:-}" ] && [ -f "$ENV_FILE" ]; then
      AGENT_INSTALL_USER=$(grep -m1 '^AGENT_INSTALL_USER=' "$ENV_FILE" | cut -d'=' -f2-) || true
    fi
    if [ -z "${AGENT_INSTALL_PASS:-}" ] && [ -f "$ENV_FILE" ]; then
      AGENT_INSTALL_PASS=$(grep -m1 '^AGENT_INSTALL_PASS=' "$ENV_FILE" | cut -d'=' -f2-) || true
    fi
    _ERR=0
    if [ -z "${AGENT_INSTALL_USER:-}" ]; then
      echo "Error: AGENT_INSTALL_USER is not set. Add it to .env or your shell environment." >&2
      _ERR=1
    fi
    if [ -z "${AGENT_INSTALL_PASS:-}" ]; then
      echo "Error: AGENT_INSTALL_PASS is not set. Add it to .env or your shell environment." >&2
      _ERR=1
    fi
    [ "$_ERR" -eq 1 ] && exit 1
    curl -fLs --user "${AGENT_INSTALL_USER}:${AGENT_INSTALL_PASS}" "https://agents.inscript.pl/install/${FORCE_PARAM}" | bash
    ;;
  update|sync|rules-list)
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
    esac
    ;;
#  skills-list)
#    composer list-skills
#    ;;
  *)
    echo "Usage: ddev ai <command>"
    echo ""
    echo "Commands:"
    echo "  init        Install AI agent tooling"
    echo "  update      Update packages and sync all AI tooling"
    echo "  sync        Manually sync rules without updating packages"
    echo "  rules-list  List installed agent-rules packages"
    exit 1
    ;;
esac

