#!/bin/bash
#sb-generated

## Description: [BASE] Run front task build or watch. You can activate option -n (--no-install) which means that no package update is run before build and watch command which speed up a lot.
## Usage: front
## Example: "ddev front build OR ddev front watch OR ddev front build -n OR ddev front watch -n"

TEXT_RED=$(tput setaf 1)
TEXT_RESET=$(tput sgr0)

NO_INSTALL=0
if [[ $2 = "-n" ]] || [[ $2 = "--no-install" ]]; then
    NO_INSTALL=1
else
    if [[ ! $2 = "" ]]; then
        echo "${TEXT_RED}No such option: '$2'. Possible option is -n (--no-install)".
        exit 1
    fi
fi

cd "$PATH_FRONTEND" || exit 1

NODE_VERSION=$(node -v)
NVMRC_NODE_VERSION=$(nvm version "$(cat .nvmrc)")
if [ "$NVMRC_NODE_VERSION" = "N/A" ]; then
  nvm install
elif [ "$NVMRC_NODE_VERSION" != "$NODE_VERSION" ]; then
  nvm use
fi

possibleArguments=(build watch)
if [[ ! ${possibleArguments[*]} =~ $1 ]]; then
    info=$(printf ", %s" "${possibleArguments[@]}")
    info=${info:1}
    echo "${TEXT_RED}Error! Wrong argument. Possible arguments are:${info}${TEXT_RESET}. If you do not want to install packages add argument -n or --noinstall"
fi

if [[ $1 = "build" ]]; then
    if [[ $NO_INSTALL = "1" ]]; then
        ${FRONTEND_BUILD_NO_PACKAGE_INSTALL}
    else
        ${FRONTEND_BUILD}
    fi
fi

if [[ $1 = "watch" ]]; then
    if [[ $NO_INSTALL = "1" ]]; then
        ${FRONTEND_WATCH_NO_PACKAGE_INSTALL}
    else
        ${FRONTEND_WATCH}
    fi
fi
