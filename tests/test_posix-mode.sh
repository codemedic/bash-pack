#!/bin/bash

set -eu

source_sut_script=1 \
    . "$(dirname "$0")/../initialise-test.sh"

# Provide stubs that can be used for testing
warn() {
    echo "$*"
}

bail() {
    echo "BAIL: $*"
    return 1
}

# turn it on and check
set -o posix
posix_mode_is_on || false

# turn it off and check
set +o posix
posix_mode_is_on || true

# turn it on, then disable and then check
set -o posix
posix_mode_disable &>/dev/null
posix_mode_is_on || true

# now that it is off, make sure no warning comes out
[ '' = "$(posix_mode_warn_if_on message 2>&1)" ]

# turn it back on and make sure the message comes out
set -o posix
[[ "$(posix_mode_warn_if_on message 2>&1)" = *message ]]

# warn and bail
( bail=1 posix_mode_warn_if_on &>/dev/null ) || true
[[ "$(bail=1 posix_mode_warn_if_on message 2>&1)" = *message ]]
