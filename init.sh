#!/bin/bash

if [ -z "${BASH_VERSION+Defined?}" ]; then
    echo "bash-pack: No shell interpreter other than Bash is supported"
    exit 1
fi

# enable / disable bash-debug based on environment variable.
#
# Globals:
#   bash_debug set to 1 to enable xtrace
enable_bash_debug() {
    [ "${bash_debug:-0}" = 0 ] ||
        set -x
}

# Check major version of bash to be at least a given number
#
# Arguments:
#   1. major_version version to check against
#
# Returns:
#   0 if greater than or equal to major_version, otherwise 1
is_bash_version() {
    (( ${BASH_VERSION%%.*} >= "$1" ))
}

# initialise and load specified scripts; fenced by __bash_pack_loaded
[ -n "${__bash_pack_loaded:-}" ] || {
    __bash_pack_loaded=1

    modules_loading=(init)

    in_array() {
        for ((i=2; i<=$#; ++i)); do
            [ "${!i}" != "$1" ] || return 0
        done
        return 1
    }

    # Locate components of a module (also the bash version is taken into account)
    bash_pack_module_locate_scripts() {
        [[ ${BASH_VERSION} =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]
        local version_Mmp="${BASH_REMATCH[0]}" \
            version_Mm="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}" \
            version_M="${BASH_REMATCH[1]}"
        local paths=( $(printf "${BASH_PACK_DIR}/${1}-bv%s.sh\n" "${version_Mmp}" "${version_Mm}" "${version_M}") "${BASH_PACK_DIR}/${1}.sh" )
        local path
        for path in "${paths[@]}"; do
            if [ -f "$path" ] && [ -r "$path" ]; then
                echo -n "$path"
                return 0
            fi
        done
        return 1
    }

    bash_pack_module_get_new_required_modules() {
        local module all_new_required_modules new_required_modules=()
        all_new_required_modules=( $(sed -nr 's/.*^#require (.*)$.*/\1/p' "$@") )
        for module in "${all_new_required_modules[@]+"${all_new_required_modules[@]}"}"; do
            in_array "$module" "${modules_loading[@]}" "${new_required_modules[@]+"${new_required_modules[@]}"}" ||
                new_required_modules+=("$module")
        done
        printf '%s\n' "${new_required_modules[@]+"${new_required_modules[@]}"}"
    }

    bash_pack_module_load_by_name() {
        local path pre_path post_path this_module_paths=()

        if in_array "$1" "${modules_loading[@]}"; then
            return 0
        fi

        if ! path="$( bash_pack_module_locate_scripts "${1}" )"; then
            echo "Could not find module: ${1}"
            exit 1
        fi

        # locate and load the module
        modules_loading+=("${1}")
        if pre_path="$( bash_pack_module_locate_scripts "${1}-pre" )"; then
            this_module_paths+=("$pre_path")
        fi
        this_module_paths+=( "$path" )
        if post_path="$( bash_pack_module_locate_scripts "${1}-post" )"; then
            this_module_paths+=("$post_path")
        fi

        # look for direct deps
        local required_modules=( $(bash_pack_module_get_new_required_modules "${this_module_paths[@]}") )
        local module
        for module in "${required_modules[@]+"${required_modules[@]}"}"; do
            bash_pack_module_load_by_name "$module"
        done

        printf '%s\n' "${this_module_paths[@]}"
    }

    BASH_PACK_DIR="${BASH_SOURCE[0]%/*}"
    [ -d "$BASH_PACK_DIR" ] || BASH_PACK_DIR=.

    enable_bash_debug

    scripts_loading=()
    # Find files to load for any module-names given as args
    for ((i=1; i<=$#; ++i)); do
        scripts_loading+=($(bash_pack_module_load_by_name "${!i}"))
    done

    # once all of them are found, load them
    for script in "${scripts_loading[@]+"${scripts_loading[@]}"}"; do
        # shellcheck disable=SC1090
        . "$script"
    done
}
