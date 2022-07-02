#!/bin/bash
#sb-generated

## Description: Run npm inside the web container in the root of the project
## Usage: npm [flags] [args]
## Example: "ddev npm i"

TEXT_RED=$(tput setaf 1)
TEXT_RESET=$(tput sgr0)

if [[ ! -e "${FRONTEND_PATH}" ]]; then echo "${TEXT_RED}No FRONTEND_PATH folder: ${FRONTEND_PATH}${TEXT_RESET}" && exit 1; fi;
cd ${FRONTEND_PATH}

if [[ ! -e .nvmrc ]]; then echo "${TEXT_RED}No file .nvmrc with node version in folder: ${FRONTEND_PATH}${TEXT_RESET}" && exit 1; fi;

nvm install --latest-npm

npm "$@"
