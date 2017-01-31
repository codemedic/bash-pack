#!/bin/bash

set -e
[ "${bash_debug:-0}" = 0 ] || set -x

ok_or_failed() {
    if [ $? -eq 0 ]; then
        echo OK
    else
        echo FAILED
    fi
}
trap ok_or_failed EXIT

: "${sut_script:="$(basename "$0" | sed 's/^test_//g')"}"
echo -n "Testing ${sut_script} ... "

: "${script:=$(dirname "$0")/../${sut_script}}"
[ "${source_sut_script:-0}" = 1 ] && [ -r "$script" ] &&
    {
        . "$script"
        return
    }

[ -x "${script}" ] && return

echo -n "SUT ($script) not found ... " && false
