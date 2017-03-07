#!/bin/bash

# This is the entry point script for bash-pack.
#
# When loading bash-pack from your script, you can specify what modules need to be loaded, as command line to the
# "sourcing" line.
#
# Usage:
#    # Initialise bash-pack and load module1.sh and module2.sh (from bash-pack)
#    . /path/to/bash-pack/init.sh module1 module2

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
if [ -z "${__bash_pack_loaded:-}" ]; then
    __bash_pack_loaded=1

    in_array() {
        for ((i=2; i<=$#; ++i)); do
            [ "${!i}" != "$1" ] || return 0
        done
        return 1
    }

    __bash_pack_component_stack=()
    bash_pack_component_stack_peek() {
        [ ${#__bash_pack_component_stack[@]} -gt 0 ] &&
            echo -n "${__bash_pack_component_stack[0]}"
    }

    bash_pack_component_stack_pop() {
        [ ${#__bash_pack_component_stack[@]} -gt 0 ] && {
            if [ ${#__bash_pack_component_stack[@]} -gt 1 ]; then
                local temp=(
                    "${__bash_pack_component_stack[@]:1}"
                )
                unset __bash_pack_component_stack
                __bash_pack_component_stack=("${temp[@]}")
            else
                __bash_pack_component_stack=()
            fi
        }
    }

    bash_pack_component_stack_push() {
        __bash_pack_component_stack=("$1" "${__bash_pack_component_stack[@]+"${__bash_pack_component_stack[@]}"}")
    }

    bash_pack_normalise_module_name() {
        if [[ "$1" =~ ^${BashPackRegexComponentName}:.+$ ]]; then
            echo -n "$1"
        else
            echo -n "$(bash_pack_component_stack_peek):${1}"
        fi
    }

    bash_pack_component_get_dir() {
        for ((i=0; i<${#bash_pack_components[@]}; ++i)); do
            if [[ "${bash_pack_components[$i]}" == "${1}":* ]]; then
                echo "${bash_pack_components[$i]#*:}";
                return 0
            fi
        done
        return 1
    }

    # Locate components of a module (also the bash version is taken into account)
    bash_pack_module_locate_scripts() {
        [[ ${BASH_VERSION} =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]
        local version_Mmp="${BASH_REMATCH[0]}" \
            version_Mm="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}" \
            version_M="${BASH_REMATCH[1]}"
        local module_dir; module_dir="$(bash_pack_component_get_dir "${1%%:*}")"
        local module="${1#*:}"
        local paths=( $(printf "${module_dir}/${module}-bv%s.sh\n" "${version_Mmp}" "${version_Mm}" "${version_M}") "${module_dir}/${module}.sh" )
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

        local module_name; module_name="$(bash_pack_normalise_module_name "$1")"

        if in_array "$module_name" "${modules_loading[@]}"; then
            return 0
        fi

        if ! path="$( bash_pack_module_locate_scripts "$module_name" )"; then
            echo "Could not find module: ${module_name}"
            exit 1
        fi

        # locate and load the module
        modules_loading+=("${module_name}")
        if pre_path="$( bash_pack_module_locate_scripts "${module_name}-pre" )"; then
            this_module_paths+=("$pre_path")
        fi
        this_module_paths+=( "$path" )
        if post_path="$( bash_pack_module_locate_scripts "${module_name}-post" )"; then
            this_module_paths+=("$post_path")
        fi

        # look for direct deps
        local required_modules=( $(bash_pack_module_get_new_required_modules "${this_module_paths[@]}") )
        local module
        for module in "${required_modules[@]+"${required_modules[@]}"}"; do
            # if the module is from a different component namespace, switch the context
            if [[ "$module" =~ ^${BashPackRegexComponentName}:.+$ ]] &&
                [ "$(bash_pack_component_stack_peek)" != "${module%%:*}" ]
            then
                bash_pack_component_stack_push "${module%%:*}"
                bash_pack_module_load_by_name "$module"
                bash_pack_component_stack_pop
            else
                # else continue loading from the same component
                bash_pack_module_load_by_name "$module"
            fi
        done

        printf '%s\n' "${this_module_paths[@]}"
    }

    bash_pack_check_components() {
        local found_components=()
        local found_component_paths=()
        # look for any module already loaded with the same namespace
        for ((i=0; i<${#bash_pack_components[@]}; ++i)); do
            if [[ "${bash_pack_components[$i]}" =~ ^$BashPackRegexComponentName:(.+)$ ]] &&
                { [ ${#found_components[@]} -eq 0 ] || ! in_array "${BASH_REMATCH[1]}" "${found_components[@]}"; } &&
                { [ ${#found_component_paths[@]} -eq 0 ] || ! in_array "${BASH_REMATCH[2]}" "${found_component_paths[@]}"; } &&
                [ -d "${BASH_REMATCH[2]}" ] && [ -r "${BASH_REMATCH[2]}" ] && [ -x "${BASH_REMATCH[2]}" ]
            then
                found_components+=("${BASH_REMATCH[1]}")
                found_component_paths+=("${BASH_REMATCH[2]}")
            else
                echo "Invalid bash-pack components definition; $((i+1)): '${bash_pack_components[$i]}'"
                return 1
            fi
        done
    }

    ## start loading scripts

    modules_loading=('bash-pack:init')

    if ! declare -p bash_pack_components >/dev/null 2>&1; then
        bash_pack_components=()
    fi

    BashPackRegexComponentName='([A-Za-z][-A-Za-z0-9_]+)'

    BASH_PACK_DIR="${BASH_SOURCE[0]%/*}"
    [ -d "$BASH_PACK_DIR" ] || BASH_PACK_DIR=.

    enable_bash_debug

    # make sure all configured components are present on disk
    bash_pack_check_components

    # Add self to the list of enabled components
    bash_pack_components+=("bash-pack:${BASH_PACK_DIR}")

    # set the context for the initial component, which is bash-pack itself
    # this is so that bash-pack modules does not need to specify itself as namespace
    bash_pack_component_stack_push 'bash-pack'

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
fi
