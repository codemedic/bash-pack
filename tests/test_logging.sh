#!/bin/bash

set -eu

# shellcheck disable=SC1090
. "$(dirname "$0")/../init.sh" initialise-test logging

# shellcheck disable=SC2034
log_common_prefix=XXX

log_initialise

log warning bla bla
log warning bla bla
