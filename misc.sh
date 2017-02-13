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

