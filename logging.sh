#!/bin/bash

#require posix-mode

# some of the bash features not available in POSIX mode, is needed here
posix_mode_disable

declare -A log_fds
log_level_initialise() {
    local level fd log_fd

    # validate and normalise it into number
    level="$(log_level_get_integer "$1")"

    # close it if it is already setup (helps reinitialisation)
    if [ -v "log_fds[${level}]" ]; then
        exec "${log_fds[$level]}">&-
    fi

    # if the set log-level allows the level being initialised, the set it up, otherwise pipe it to NULL
    if [ "$log_level" -ge "$level" ]; then
        if [ "$log_level" -ge "$(log_level_get_integer notice)" ]; then
            log_fd="${log_info_fd}"
        else
            log_fd="${log_error_fd}"
        fi
        # shellcheck disable=SC2154
        exec {fd}> >(out_fd="$log_fd" prefix_filter "$(to_upper "${log_level_names[$level]}"): ")
    fi

    log_fds[$level]="${fd:-"${o_null:-2}"}"
}

log_level_get_fd() {
    local level level_name

    level_name="$1"; shift

    # validate and normalise it into number
    level="$(log_level_get_integer "$level_name")"

    echo -n "${log_fds[$level]}"
}

log_initialise() {
    # Enable / disable debug level logging
    if [ "${debug:-0}" = 1 ]; then
        log_level=debug
    fi

    # set log_level; converting if non-numeric
    log_set_level "$log_level"

    # Cannot reinitialise
    if [ "${log:-XX}" != XX ]; then
        return 0;
    fi

    # duplicate the three FDs
    # exec {o_stdin}<&0
    exec {o_stdout}>&1
    exec {o_stderr}>&2
    exec {o_null}>/dev/null

    # setup log-file if specified
    if [ -n "${log_file:-}" ]; then
        exec {log}>>"$log_file"
    else
        # if no log-file is specified, fd $log is stderr
        exec {log}>&"${o_stderr:-2}"
        # if informational logs are to go to stdout (as in the case of atlassian bamboo build env)
        [ "${log_info_to_stdout:-0}" = 0 ] ||
            log_info_fd="${o_stdout:-1}"
    fi

    log_error_fd="${log}"
    : "${log_info_fd:="${log}"}"

    for i in "${log_level_names[@]}"; do
        log_level_initialise "$i"
    done
}
