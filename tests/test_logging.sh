#!/bin/bash

set -eu

. "$(dirname "$0")/../common.sh" posix-mode
source_sut_script=1 \
    . "$(dirname "$0")/../initialise-test.sh"

log_initialise
