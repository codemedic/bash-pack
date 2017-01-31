#!/bin/bash

# @param Level
log() {
    # get the fd from log-level-name
    local fd; fd="$(log_level_get_fd "$1")"; shift

    # log only if fd is NOT same as o_null
    if [ "$fd" != "$o_null" ]; then
        echo "$*" >&"${fd}"
    fi

    return 0
}

# @param Level
# @param Prefix
log_pipe() {
    # get the fd from log-level-name
    local fd; fd="$(log_level_get_fd "$1")"; shift

    # if fd is same as o_null, then read and ignore (by not asking to write to an fd)
    if [ "$fd" = "$o_null" ]; then
        tee="${tee:-0}" pipe_to_fd
    # else if no prefix specified
    elif [ $# -eq 0 ]; then
        tee="${tee:-0}" pipe_to_fd "${fd}"
    # else (if prefix specified) add prefix_filer to log-level-fd
    else
        tee="${tee:-0}" pipe_to_file >(out_fd="${fd}" prefix_filter "$*")
    fi

    return 0
}

# lines read from stdin written to $log setup above
#
# @param Level
# @param Prefix
log_tee() {
    tee=1 log_pipe "$@"
}

# Exit with an error message
#
# @param ErrorMessage
#
# @var exit_code set to a number which will be used as exit code
bail() {
    log error "$*"
    exit "${exit_code:-1}"
}
