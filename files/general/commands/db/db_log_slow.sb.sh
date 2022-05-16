#!/bin/bash
#sb-generated

## Description: Show database slow_query_log. Default long_query_time is 1 second.
## Usage: db_log_slow 0.5

TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)

LONG_QUERY_TIME_DEFAULT=1
LONG_QUERY_TIME=${1:-$LONG_QUERY_TIME_DEFAULT}

function enable() {
    echo "${TEXT_GREEN}"
    echo "Enabling slow_log"
    echo "Press CTRL+C to exit"
    echo "Long query time is: ${LONG_QUERY_TIME}"
    echo "${TEXT_RESET}"
    sleep 2
    mysql -uroot -proot <<< "SET GLOBAL slow_query_log_file='slow_log.log'"
    mysql -uroot -proot <<< "SET GLOBAL slow_query_log=1" &
    mysql -uroot -proot <<< "SET GLOBAL long_query_time=${LONG_QUERY_TIME}" &
#    mysql -uroot -proot <<< "SET GLOBAL log_queries_not_using_indexes=1" &
#    mysql -uroot -proot <<< "SET GLOBAL log_throttle_queries_not_using_indexes=100" &
}

function shutdown() {
    echo "${TEXT_GREEN}"
    echo "Disabling slow_log"
    echo "${TEXT_RESET}"
    mysql -uroot -proot <<< "SET GLOBAL slow_query_log=0" &
    exit 0
}

trap shutdown INT
enable
tail -f /var/lib/mysql/slow_log.log | grep -E -v "^(Tcp port|mysqld, Version:|Time)"
