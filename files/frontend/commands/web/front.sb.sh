#!/bin/bash
#sb-generated

## Description: [BASE] Run front task build or watch. The possible arguments are build, watch, build-noci, watch-noci. The "no-ci" means that "npm ci" is not run before build command which speed up a lot.
## Usage: front
## Example: "ddev front build OR ddev front watch OR ddev front build-noci OR ddev front watch-noci"

TEXT_RED=$(tput setaf 1)
TEXT_RESET=$(tput sgr0)

cd "$PATH_FRONTEND" || exit 1

NODE_VERSION=$(node -v)
NVMRC_NODE_VERSION=$(nvm version "$(cat .nvmrc)")
if [ "$NVMRC_NODE_VERSION" = "N/A" ]; then
  nvm install
elif [ "$NVMRC_NODE_VERSION" != "$NODE_VERSION" ]; then
  nvm use
fi

possibleArguments=(build build-noci watch watch-noci)
if [[ ! ${possibleArguments[*]} =~ $1 ]]; then
    info=$(printf ", %s" "${possibleArguments[@]}")
    info=${info:1}
    echo "${TEXT_RED}Error! Wrong argument. Possible arguments are: ${info}${TEXT_RESET}"
fi

if [[ $1 = "build" ]]; then
    npm ci
    ${FRONTEND_BUILD}
fi

if [[ $1 = "watch" ]]; then
    npm ci
    ${FRONTEND_WATCH}
fi

if [[ $1 = "build-noci" ]]; then
    ${FRONTEND_BUILD}
fi

if [[ $1 = "watch-noci" ]]; then
    ${FRONTEND_WATCH}
fi
