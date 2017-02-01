#!/bin/bash

set -eu

. "$(dirname "$0")/../common.sh" \
    logging-depricated

log_initialise

debug "some-value : bla"
info "Some value was unexpected"
error "Something broke!"

log_tee debug < /etc/hosts | grep localhost
