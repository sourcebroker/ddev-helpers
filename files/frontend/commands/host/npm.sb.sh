#!/bin/bash
#sb-generated

## Description: Run npm inside the web container in the root of the project (Use --cwd for another directory)
## Usage: npm [flags] [args]
## Example: "ddev npm i"

ddev exec --raw bash -ic "npm '$@'"
ddev mutagen sync 2>/dev/null
