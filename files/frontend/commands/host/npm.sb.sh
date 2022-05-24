#!/bin/bash
#sb-generated

## Description: Run npm inside the web container in the root of the project (Use --cwd for another directory)
## Usage: npm [flags] [args]
## Example: "ddev npm i"

ddev exec --raw bash -ic "TEXT_RED=\$(tput setaf 1) TEXT_RESET=\$(tput sgr0) && echo \"Opening \${FRONTEND_PATH}\" && if [[ -e \"\${FRONTEND_PATH}\" ]]; then cd \"\$FRONTEND_PATH\" && npm '$@'; else echo \"\${TEXT_RED}No FRONTEND_PATH folder: \${FRONTEND_PATH}\${TEXT_RESET}\"; fi;"
ddev mutagen sync 2>/dev/null
