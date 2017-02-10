#!/bin/bash

set -eu

. "$(dirname "$0")/../common.sh" initialise-test logging

log_common_prefix=XXX

log_initialise

log warning bla bla
log warning bla bla
