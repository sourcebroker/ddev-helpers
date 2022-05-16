#!/bin/bash
#sb-generated

## Description: [BASE] Run front task (on host side!)
## Usage: fronth
## Example: "ddev fronth build OR ddev fronth watch"

source $DDEV_APPROOT/.ddev/commands/host/.fronth_env

if [[ $1 = "build" ]]; then
    npm ci
    eval ${FRONTEND_BUILD}
fi

if [[ $1 = "watch" ]]; then
    npm ci
    eval ${FRONTEND_WATCH_HOST}
fi

if [[ $1 = "build-noci" ]]; then
    eval ${FRONTEND_BUILD}
fi

if [[ $1 = "watch-noci" ]]; then
    eval ${FRONTEND_WATCH_HOST}
fi
