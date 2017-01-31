#!/bin/bash

# some of the bash features not available in POSIX mode, is needed here
posix_mode_disable

log_level_names=(emergency alert critical error warning notice info debug)

if is_bash_version 4; then
    declare -A log_levels
    log_levels=(
        [emergency]=0 [0]=0
        [alert]=1     [1]=1
        [critical]=2  [2]=2
        [error]=3     [3]=3
        [warning]=4   [4]=4
        [notice]=5    [5]=5
        [info]=6      [6]=6
        [debug]=7     [7]=7
    )

    log_level_get_integer() {
        local level="$1"
        if [[ "$level" =~ ^[0-7]$ ]]; then
            echo -n "$level"
        else
            level="log_levels[$(to_lower "$level")]"
            [ -v "$level" ] && echo -n "${!level}"
        fi
    }
else
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
fi

: "${log_level:=6}"
log_set_level() {
    log_level="$(log_level_get_integer "$1")" || {
        echo "Unknown log level" 1>&2
        exit 1
    }
}

if is_bash_version 4; then
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
else
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
        local level level_name fd log_fd

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
fi


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

    if is_bash_version 4; then
        # duplicate the three FDs
        exec {o_stdin}<&0
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
    else
        # duplicate the three FDs
        o_stdin="$(unused_fd)"
        eval "exec ${o_stdin}<&0"
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
    fi

    log_error_fd="${log}"
    : "${log_info_fd:="${log}"}"

    for i in "${log_level_names[@]}"; do
        log_level_initialise "$i"
    done
}

# @param Level
log() {
    # get the fd from log-level-name
    local fd; fd="$(log_level_get_fd "$1")"; shift

    # if fd is same as o_null, don't log
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

    # if fd is same as o_null, don't log
    if [ $# -eq 0 ]; then
        tee="${tee:-0}" pipe_to_fd "${fd}"
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
