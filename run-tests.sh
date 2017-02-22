#!/bin/bash

set -eu

# shellcheck disable=SC1090
. "$(dirname "$0")/common.sh" logging

usage_help() {
    [ -z "$*" ] || error "$*"$'\n'
    cat <<HELP
run-tests.sh - Run tests from a directory

It looks for all executable files named "test_*.sh" and execute them one after the other.
If there are any failures, it will stop straight away (by default).

Usage:
    run-tests.sh [--directory=<TestsDirectory>] [--continue-on-failure]

Options:
    -d <TestsDirectory>, --directory=<TestsDirectory>
        Run all tests from the specified directory; if not specified, a directory called "tests" in the current
        directory will be used.

    -c, --continue-on-failure
        Continue on failures
HELP
    [ -z "$*" ] || exit 1
}

cli_opts="$(getopt -n "$(basename "$0")" -o cd:h --long continue-on-failure,directory:,help -- "$@" )" || {
    usage_help "Invalid usage"
}
eval "cli_opts=( ${cli_opts} )"
for ((i = 0; i < ${#cli_opts[@]}; ++i)); do
    case "${cli_opts[$i]}" in
        -c|--continue-on-failure)
            continue_on_failure=1
            ;;
        -d|--directory)
            tests_directory="${cli_opts[$((++i))]}"
            ;;
        -h|--help)
            usage_help
            exit 0
            ;;
        --)
            ;;
        *)
            usage_help "Invalid usage"
            ;;
    esac
done

enable_bash_debug
log_initialise

: "${tests_directory:="$(pwd)/tests"}"
if [ ! -d "$tests_directory" ]; then
    echo "ERROR: tests_directory: $tests_directory - not found"
    exit 1
fi

log info "Running tests from $tests_directory"

# XXX be aware that the below formula is not bullet proof WRT space character in file/dir names
test_scripts=( $(find "$tests_directory/" -maxdepth 1 -type f -name 'test_*.sh') )
[ ${#test_scripts[@]} -gt 0 ] || {
    echo "ERROR: No test scripts found in $tests_directory/"
    exit 1
}
for test_script in "${test_scripts[@]}"; do
    "$test_script" || {
        [ "${continue_on_failure:-0}" = 1 ] ||
            exit 1
    }
done
