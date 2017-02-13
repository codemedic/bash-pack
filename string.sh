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

