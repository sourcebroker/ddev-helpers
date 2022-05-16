#!/bin/bash
#sb-generated

## Description: Show database general_log. There is filtering active for lines that start with "Prepare|Close stmt|Quit|Connect|Query|Tcp port|mysqld, Version:"
## Usage: db_log_general

TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)

function enable() {
    echo "${TEXT_GREEN}"
    echo "Enabling general_log"
    echo "Press CTRL+C to exit"
    echo "${TEXT_RESET}"
    mysql -uroot -proot <<< "SET GLOBAL general_log_file='general_log.log'"
    mysql -uroot -proot <<< "SET GLOBAL general_log=1" &
}

function shutdown() {
    echo "${TEXT_GREEN}"
    echo "Disabling general_log"
    echo "${TEXT_RESET}"
    mysql -uroot -proot <<< "SET GLOBAL general_log=0" &
    exit 0
}

trap shutdown INT
enable
sleep 2
tail -f /var/lib/mysql/general_log.log | grep -E -v "(Prepare|Close stmt|Quit|Connect|Query|Tcp port|mysqld, Version:)"
