#!/bin/bash

_log_level_fd_var() {
    echo -n "log_fds_${1}"
}

_log_level_fd_new() {
    local new_fd
    local level_name="$1"; shift
    local target_fd="$1"; shift
    local fd_var; fd_var="$(_log_level_fd_var "$level_name")"

    # if null-fd is the target, dont setup prefix filter
    if [ "${target_fd}" = "${o_null}" ]; then
        new_fd="${o_null}"
    else
        # if already defined, and is an fd, close it
        [ -z "${!fd_var+XX}" ] || {
            ! is_fd "${!fd_var}" || {
                eval "exec ${!fd_var}>&-"
            }
            # recycle the fd
            new_fd="${!fd_var}"
        }

        # if new_fd not set yet, get an unused fd
        : "${new_fd:="$(unused_fd)"}"

        eval "exec ${new_fd}> >(out_fd=${target_fd} prefix_filter '$(to_upper "$level_name"): ')"
    fi
    eval "${fd_var}=${new_fd}"
}

log_level_initialise() {
    local level level_name log_fd

    level_name="$1"; shift

    # validate and normalise it into number
    level="$(log_level_get_integer "$level_name")"

    # if the set log-level allows the level being initialised, the set it up, otherwise pipe it to NULL
    if [ "$log_level" -ge "$level" ]; then
        if [ "$log_level" -ge "$(log_level_get_integer notice)" ]; then
            log_fd="${log_info_fd}"
        else
            log_fd="${log_error_fd}"
        fi
    else
        log_fd="${o_null}"
    fi

    _log_level_fd_new "$level_name" "$log_fd"
}

log_level_get_fd() {
    local fd_var; fd_var="$(_log_level_fd_var "$1")"
    echo -n "${!fd_var}"
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
    # o_stdin="$(unused_fd)"
    # eval "exec ${o_stdin}<&0"
    o_stdout="$(unused_fd)"
    eval "exec ${o_stdout}>&1"
    o_stderr="$(unused_fd)"
    eval "exec ${o_stderr}>&2"
    o_null="$(unused_fd)"
    eval "exec ${o_null}>/dev/null"

    log="$(unused_fd)"
    # setup log-file if specified
    if [ -n "${log_file:-}" ]; then
        eval "exec ${log}>>\"${log_file}\""
    else
        # if no log-file is specified, fd $log is stderr
        eval "exec ${log}>&${o_stderr:-2}"
        # if informational logs are to go to stdout (as in the case of atlassian bamboo build env)
        [ "${log_info_to_stdout:-0}" = 0 ] ||
            log_info_fd="${o_stdout:-1}"
    fi

    log_error_fd="${log}"
    : "${log_info_fd:="${log}"}"

    # log_level_names variable comes from logging-pre
    # shellcheck disable=SC2154
    for i in "${log_level_names[@]}"; do
        log_level_initialise "$i"
    done
}
