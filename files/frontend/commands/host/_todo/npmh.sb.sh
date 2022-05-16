#!/bin/bash
#sb-generated

## Description: [BASE] Run npm command in context of frontend project path (on host side!)
## Usage: npmh
## Example: "ddev npmh ci"

source .ddev/commands/host/.fronth_env
npm $@
