#!/bin/bash
#sb-generated

## Description: Run npm inside the web container in the root of the project
## Usage: npm [flags] [args]
## Example: "ddev npm i"

TEXT_RED=$(tput setaf 1)
TEXT_RESET=$(tput sgr0)

if [[ ! -e "${ASSETS_FRONTEND_SRC}" ]]; then echo "${TEXT_RED}No ASSETS_FRONTEND_SRC folder: ${ASSETS_FRONTEND_SRC}${TEXT_RESET}" && exit 1; fi;
cd "${ASSETS_FRONTEND_SRC}" || exit 1

if [[ ! -e .nvmrc ]]; then echo "${TEXT_RED}No file .nvmrc with node version in folder: ${ASSETS_FRONTEND_SRC}${TEXT_RESET}" && exit 1; fi;

nvm install --latest-npm

npm "$@"
