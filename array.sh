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

