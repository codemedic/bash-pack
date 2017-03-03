#!/bin/bash

set -eu

# shellcheck disable=SC1090
. "$(dirname "$0")/../init.sh" \
    logging-depricated

log_initialise

debug "some-value : bla"
info "Some value was unexpected"
error "Something broke!"

log_tee debug < /etc/hosts | grep localhost
