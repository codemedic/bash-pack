#!/bin/bash

#require posix-mode
#require file
#require string

# some of the bash features not available in POSIX mode, is needed here
posix_mode_disable

log_level_names=(emergency alert critical error warning notice info debug)

log_level_get_integer() {
    case "$1" in
        [0-7])
            echo -n "$1"
            ;;
        *)
            local level
            level="$(to_lower "$1")"
            for ((i=0; i<${#log_level_names[@]}; ++i)); do
                [ "$level" != "${log_level_names[$i]}" ] || {
                    echo -n "$i"
                    return 0
                }
            done
            return 1
            ;;
    esac
}

: "${log_level:=6}"
log_set_level() {
    log_level="$(log_level_get_integer "$1")" || {
        echo "Unknown log level" 1>&2
        exit 1
    }
}

# Is common log line prefix (application name and/or pid) defined?
# log_common_prefix=app-name
# log_common_prefix="app-name[$$]"
