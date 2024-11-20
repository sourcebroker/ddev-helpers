#!/bin/bash
#sb-generated

## Description: [BASE] Run front task build or watch. You can activate option -n (--no-install) which means that no package update is run before build and watch command which speed up a lot.
## Usage: front
## Example: "ddev front build OR ddev front watch OR ddev front build -n OR ddev front watch -n"

TEXT_RED=$(tput setaf 1)
TEXT_RESET=$(tput sgr0)

NO_INSTALL=0
CONFIG=""
COMMAND=""

for arg in "$@"; do
  case $arg in
    -n|--no-install)
      NO_INSTALL=1
      shift
      ;;
    -c|--config)
      CONFIG="${2}"
      shift 2
      ;;
    --config=*)
      CONFIG="${arg#*=}"
      shift
      ;;
    build|watch)
      COMMAND=$arg
      shift
      ;;
    *)
      ;;
  esac
done

if [[ -z "$COMMAND" ]]; then
  echo "${TEXT_RED}Error! Wrong argument. Possible arguments are: build, watch. If you do not want to install packages add argument -n or --noinstall${TEXT_RESET}"
  exit 1
fi

if [[ -n "${CONFIG}" ]]; then
  ASSETS_FRONTEND_SRC_VAR="ASSETS_FRONTEND_SRC_${CONFIG}"
  ASSETS_FRONTEND_DIST_VAR="ASSETS_FRONTEND_DIST_${CONFIG}"
  ASSETS_FRONTEND_BUILD_VAR="ASSETS_FRONTEND_BUILD_${CONFIG}"
  ASSETS_FRONTEND_BUILD_NO_PACKAGE_INSTALL_VAR="ASSETS_FRONTEND_BUILD_NO_PACKAGE_INSTALL_${CONFIG}"
  ASSETS_FRONTEND_WATCH_VAR="ASSETS_FRONTEND_WATCH_${CONFIG}"
  ASSETS_FRONTEND_WATCH_NO_PACKAGE_INSTALL_VAR="ASSETS_FRONTEND_WATCH_NO_PACKAGE_INSTALL_${CONFIG}"

  if [[ -z $(eval echo \$$ASSETS_FRONTEND_SRC_VAR) ]]; then
    echo "${TEXT_RED}The config for \`${CONFIG}\` is not set (checked ASSETS_FRONTEND_SRC_${CONFIG})${TEXT_RESET}"
    exit 1
  fi

  if [[ -z $(eval echo \$$ASSETS_FRONTEND_DIST_VAR) ]]; then
    echo "${TEXT_RED}The config for \`${CONFIG}\` is not set (checked ASSETS_FRONTEND_DIST_${CONFIG})${TEXT_RESET}"
    exit 1
  fi

  [[ -n $(eval echo \$$ASSETS_FRONTEND_SRC_VAR) ]] && ASSETS_FRONTEND_SRC=$(eval echo \$$ASSETS_FRONTEND_SRC_VAR)
  [[ -n $(eval echo \$$ASSETS_FRONTEND_DIST_VAR) ]] && ASSETS_FRONTEND_DIST=$(eval echo \$$ASSETS_FRONTEND_DIST_VAR)
  [[ -n $(eval echo \$$ASSETS_FRONTEND_BUILD_VAR) ]] && ASSETS_FRONTEND_BUILD=$(eval echo \$$ASSETS_FRONTEND_BUILD_VAR)
  [[ -n $(eval echo \$$ASSETS_FRONTEND_BUILD_NO_PACKAGE_INSTALL_VAR) ]] && ASSETS_FRONTEND_BUILD_NO_PACKAGE_INSTALL=$(eval echo \$$ASSETS_FRONTEND_BUILD_NO_PACKAGE_INSTALL_VAR)
  [[ -n $(eval echo \$$ASSETS_FRONTEND_WATCH_VAR) ]] && ASSETS_FRONTEND_WATCH=$(eval echo \$$ASSETS_FRONTEND_WATCH_VAR)
  [[ -n $(eval echo \$$ASSETS_FRONTEND_WATCH_NO_PACKAGE_INSTALL_VAR) ]] && ASSETS_FRONTEND_WATCH_NO_PACKAGE_INSTALL=$(eval echo \$$ASSETS_FRONTEND_WATCH_NO_PACKAGE_INSTALL_VAR)
fi

if [[ ! -e "${ASSETS_FRONTEND_SRC}" ]]; then echo "${TEXT_RED}No ASSETS_FRONTEND_SRC folder: ${ASSETS_FRONTEND_SRC}${TEXT_RESET}" && exit 1; fi;
cd "${ASSETS_FRONTEND_SRC}" || exit 1

if [[ ! -e .nvmrc ]]; then echo "${TEXT_RED}No file .nvmrc with node version in folder: ${ASSETS_FRONTEND_SRC}${TEXT_RESET}" && exit 1; fi;

if [[ $COMMAND = "build" ]]; then
    if [[ $NO_INSTALL = "1" ]]; then
        bash -ic "${ASSETS_FRONTEND_BUILD_NO_PACKAGE_INSTALL}"
    else
        bash -ic "${ASSETS_FRONTEND_BUILD}"
    fi
fi

if [[ $COMMAND = "watch" ]]; then
    if [[ $NO_INSTALL = "1" ]]; then
        bash -ic "${ASSETS_FRONTEND_WATCH_NO_PACKAGE_INSTALL}"
    else
        bash -ic "${ASSETS_FRONTEND_WATCH}"
    fi
fi
