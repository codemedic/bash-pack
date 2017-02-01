#!/bin/bash

set -e
[ "${bash_debug:-0}" = 0 ] || set -x

ok_or_failed() {
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        echo OK
    else
        echo FAILED
    fi
}
trap ok_or_failed EXIT

fail() { false; }
success() { true; }

: "${sut_script:="$(basename "$0" | sed 's/^test_//g')"}"
echo -n "Testing ${sut_script} ... "

: "${script:=$(dirname "$0")/../${sut_script}}"
[ -r "$script" ] || {
    echo -n "SUT ($script) not found ... "
    false
}
