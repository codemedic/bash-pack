#!/bin/bash

# Adds $ns as prefix if it is specified
#
# @param VariableName
nsvar_get_name() {
    [ -n "${ns:-}" ] && echo -n "${ns}_$1"
}

# Set value for the specified builder variable
#
# If it is already defined via bamboo's build variables (or other means) they are not changed
#
# @param VariableName  Unnamespaced variable name
# @param Value         if the variable is not already defined and if this value starts with '!', value is treated as
#                      function name, which will be called to set the variable. Return code from this function will be
#                      passed back to the calling function
#
# @env override set to 1 will override the value if it is already defined
nsvar_set_value() {
    local var="$1"; shift
    local value="$1"; shift
    local ns_var; ns_var="$(nsvar_get_name "$var")"
    if [ "${override:-0}" = 1 ] || [ -z "${!ns_var+XX}" ]; then
        if [ -n "$value" ]; then
            if [ "${value:0:1}" = '!' ]; then
                # call the function and let it set the variable with value
                "${value:1}" "$var" "$@"
                return
            fi
        fi

        # variable in the namespace is NOT already defined .. or
        [ -z "${!ns_var+XX}" ] || {
            # if the variable in the namespace has same value as the one given .. OR
            [ "${!ns_var}" = "$value" ] || {
                info "Overriding $ns_var ( old:'${!ns_var}' new:'$value' )"
            }
        }
        declare -g "$ns_var=$value"
    else
        info "'$var' - $ns_var already defined"
    fi
}

# Get builder variable, if defined
#
# If the variable is not defined, return error
#
# @param VariableName
nsvar_get_value() {
    local ns_var; ns_var="$(nsvar_get_name "$1")"
    if [ -z "${!ns_var+XX}" ]; then
        info "'$1' not found in namespace (full-name: $ns_var)"
        return 1
    fi
    echo -n "${!ns_var}"
}

# import builder variables from a file (into the namespace specified in $ns)
#
# @param VariablesFile
nsvar_import_variables() {
    [ -r "$1" ] || {
        bail "import_builder_variable: Unable to read from file '$1'"
    }

    local ns
    # prefix variables found from the file
    # shellcheck disable=SC1090
    . <(sed "s/^/${ns}_/g" "$1")
}

# Print builder variable (for export)
#
# @param VariableName
nsvar_print_variable() {
    echo "$1=$(get_builder_variable "$1")"
}

# Print all builder variable (for export)
nsvar_print_all_variables() {
    local line;
    local ns
    ( set -o posix; set ) | \
    while true; do
        if IFS= read -r line; then 
            [[ "$line" =~ ^${ns}_ ]] &&
                echo "${line:$((${#ns}+1))}"
        else
            break;
        fi
    done
}
