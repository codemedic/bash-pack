#!/bin/bash

if [ -z "${BASH_VERSION+Defined?}" ]; then
    echo "bash-common: No shell interpreter other than Bash is supported"
    exit 1
fi

# enable / disable bash-debug
enable_bash_debug() {
    [ "${bash_debug:-0}" = 0 ] ||
        set -x
}

is_bash_version() {
    (( ${BASH_VERSION%%.*} >= "$1" ))
}

to_lower() {
    if is_bash_version 4; then
        local str="$*"
        echo "${str,,}"
    else
        echo "$*" | tr '[:upper:]' '[:lower:]'
    fi
}

to_upper() {
    if is_bash_version 4; then
        local str="$*"
        echo "${str^^}"
    else
        echo "$*" | tr '[:lower:]' '[:upper:]'
    fi
}

prefix_filter() {
    local prefix line
    [ $# -eq 0 ] || prefix="$*"
    while true; do
        if IFS= read -r line; then
            echo "${prefix}${line}" >&"${out_fd:-1}";
        else
            break;
        fi;
    done
}

pipe_to_fd() {
    # make sure fds are valid
    for ((i=1; i<=$#; ++i)); do
        { >&"${!i}"; } 2> /dev/null ||
            bail "tee_fd: Invalid fd (${!i}) given"
    done

    while true; do
        if IFS= read -r line; then
            for ((i=1; i<=$#; ++i)); do
                echo "${line}" >&"${!i}";
            done
            [ "${tee:-0}" = 0 ] ||
                echo "${line}"
        else
            break;
        fi;
    done
}

pipe_to_file() {
    while true; do
        if IFS= read -r line; then
            for ((i=1; i<=$#; ++i)); do
                echo "${line}" >>"${!i}";
            done
            [ "${tee:-0}" = 0 ] ||
                echo "${line}"
        else
            break;
        fi;
    done
}

is_fd() {
    [[ "$1" =~ ^[0-9]+$ ]] && {
        { : >&"$1"; } 2> /dev/null
    }
}

unused_fd() {
    : "${__max_fd:="$(ulimit -n)"}"
    for ((i=0; i<"$__max_fd"; ++i)); do
        is_fd "$i" || {
            echo -n "$i"
            break;
        }
    done
}

in_array() {
    for ((i=2; i<=$#; ++i)); do
        [ "${!i}" != "$1" ] || return 0
    done
    return 1
}

array_join() {
    local glue="$1"; shift;
    if [ $# -gt 0 ]; then
        echo -n "$1"; shift
        printf "${glue}%s" "$@"
    fi
}

get_named_param() {
    local variable_name i
    variable_name="$1"; shift
    for ((i=1; i<=$#; ++i)); do
        if [[ "${!i}" == "${variable_name}"=* ]]; then
            printf '%s' "${!i:$((${#variable_name}+1))}"
            return 0
        fi
    done
    return 1
}

# initialise and load specified scripts; fenced by __bash_common_loaded
[ -n "${__bash_common_loaded:-}" ] || {
    __bash_common_loaded=1

    modules_loading=(common)

    # Locate components of a module (also the bash version is taken into account)
    common_module_locate_scripts() {
        [[ ${BASH_VERSION} =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]
        local version_Mmp="${BASH_REMATCH[0]}" \
            version_Mm="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}" \
            version_M="${BASH_REMATCH[1]}"
        local paths=( $(printf "${COMMON_DIR}/${1}-bv%s.sh\n" "${version_Mmp}" "${version_Mm}" "${version_M}") "${COMMON_DIR}/${1}.sh" )
        local path
        for path in "${paths[@]}"; do
            if [ -f "$path" ] && [ -r "$path" ]; then
                echo -n "$path"
                return 0
            fi
        done
        return 1
    }

    common_module_get_new_required_modules() {
        local module all_new_required_modules new_required_modules=()
        all_new_required_modules=( $(sed -nr 's/.*^#require (.*)$.*/\1/p' "$@") )
        for module in "${all_new_required_modules[@]+"${all_new_required_modules[@]}"}"; do
            in_array "$module" "${modules_loading[@]}" "${new_required_modules[@]+"${new_required_modules[@]}"}" ||
                new_required_modules+=("$module")
        done
        printf '%s\n' "${new_required_modules[@]+"${new_required_modules[@]}"}"
    }

    common_module_load_by_name() {
        local path pre_path post_path this_module_paths=()

        if in_array "$1" "${modules_loading[@]}"; then
            return 0
        fi

        if ! path="$( common_module_locate_scripts "${1}" )"; then
            echo "Could not find module: ${1}"
            exit 1
        fi

        # locate and load the module
        modules_loading+=("${1}")
        if pre_path="$( common_module_locate_scripts "${1}-pre" )"; then
            this_module_paths+=("$pre_path")
        fi
        this_module_paths+=( "$path" )
        if post_path="$( common_module_locate_scripts "${1}-post" )"; then
            this_module_paths+=("$post_path")
        fi

        # look for direct deps
        local required_modules=( $(common_module_get_new_required_modules "${this_module_paths[@]}") )
        local module
        for module in "${required_modules[@]+"${required_modules[@]}"}"; do
            common_module_load_by_name "$module"
        done

        printf '%s\n' "${this_module_paths[@]}"
    }

    COMMON_DIR="${BASH_SOURCE[0]%/*}"
    [ -d "$COMMON_DIR" ] || COMMON_DIR=.

    enable_bash_debug

    scripts_loading=()
    # Find files to load for any module-names given as args
    for ((i=1; i<=$#; ++i)); do
        scripts_loading+=($(common_module_load_by_name "${!i}"))
    done

    # once all of them are found, load them
    for script in "${scripts_loading[@]+"${scripts_loading[@]}"}"; do
        # shellcheck disable=SC1090
        . "$script"
    done
}
