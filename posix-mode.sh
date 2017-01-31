#!/bin/bash

posix_mode_is_on() {
    [[ "$(set +o)" =~ .*'set -o posix'.* ]]
}

posix_mode_warn_if_on() {
    if posix_mode_is_on; then
        [ $# -gt 0 ] || set -- "Bash POSIX mode is ON"
        if [ "${bail:-0}" = 1 ]; then
            echo "ERROR: $*" 1>&2
            exit 1
        else
            echo "WARNING: $*" 1>&2
        fi
    fi 
}

posix_mode_disable() {
    if posix_mode_is_on; then
        echo "INFO: Bash POSIX mode is ON; turning it off" 1>&2
        set +o posix
    fi
}
