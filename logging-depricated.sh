#!/bin/bash

# Log warnings
warn() {
    log warning "$@"
}
log_pipe_warn() {
    log_pipe warning "$@"
}

# Log errors
error() {
    log error "$@"
}
log_pipe_error() {
    log_pipe error "$@"
}

# Log info
info() {
    log info "$@"
}
log_pipe_info() {
    log_pipe info "$@"
}

# Log debug
debug() {
    log debug "$@"
}
log_pipe_debug() {
    log_pipe debug "$@"
}
debug_tee() {
    log_tee debug "$@"
}
