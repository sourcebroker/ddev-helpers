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

if [[ ! -e "${FRONTEND_PATH}" ]]; then echo "${TEXT_RED}No FRONTEND_PATH folder: ${FRONTEND_PATH}${TEXT_RESET}" && exit 1; fi;
cd ${FRONTEND_PATH}

if [[ ! -e .nvmrc ]]; then echo "${TEXT_RED}No file .nvmrc with node version in folder: ${FRONTEND_PATH}${TEXT_RESET}" && exit 1; fi;

POSSIBLE_ARGUMENTS=(build watch)
if [[ ! ${POSSIBLE_ARGUMENTS[*]} =~ $1 ]]; then
    INFO=$(printf ", %s" "${POSSIBLE_ARGUMENTS[@]}")
    INFO=${INFO:1}
    echo "${TEXT_RED}Error! Wrong argument. Possible arguments are:${INFO}${TEXT_RESET}. If you do not want to install packages add argument -n or --noinstall"
    exit 1
fi

if [[ $1 = "build" ]]; then
    if [[ $NO_INSTALL = "1" ]]; then
        bash -ic "${FRONTEND_BUILD_NO_PACKAGE_INSTALL}"
    else
        bash -ic "${FRONTEND_BUILD}"
    fi
fi

if [[ $1 = "watch" ]]; then
    if [[ $NO_INSTALL = "1" ]]; then
        bash -ic "${FRONTEND_WATCH_NO_PACKAGE_INSTALL}"
    else
        bash -ic "${FRONTEND_WATCH}"
    fi
fi
