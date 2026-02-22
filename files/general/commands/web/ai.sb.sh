#!/bin/bash

## Description: Manage AI agent tooling. Commands: update, sync, rules-list
## Usage: ai <command>
## Example: "ddev ai update"

set -euo pipefail

TOOLING_DIR="/var/www/html/.agents-tooling"
CMD="${1:-}"

if [ ! -d "$TOOLING_DIR" ]; then
  echo "Error: $TOOLING_DIR does not exist." >&2
  exit 1
fi

cd "$TOOLING_DIR"

case "$CMD" in
  update)
    composer update
    ;;
  sync)
    composer sync-rules
#    composer sync-skills
    ;;
  rules-list)
    composer list-rules
    ;;
#  skills-list)
#    composer list-skills
#    ;;
  *)
    echo "Usage: ddev ai <command>"
    echo ""
    echo "Commands:"
    echo "  update      Update packages and sync all AI tooling"
    echo "  sync        Manually sync rules without updating packages"
    echo "  rules-list  List installed agent-rules packages"
    exit 1
    ;;
esac

