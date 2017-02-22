#!/bin/bash

set -eu

. "$(dirname "$0")/../common.sh" initialise-test semver

semver_bump || success
semver_bump not-semver || success
semver_bump 0.0.0 unknown-component || success
semver_bump 0.0.0 patch not-number || success
[ 0.0.1 = "$(semver_bump 0)" ]
[ 0.0.1 = "$(semver_bump 0.0.0)" ]
[ 0.1.0 = "$(semver_bump 0.0.0 minor)" ]
[ 1.0.0 = "$(semver_bump 0.0.0 major)" ]
[ 10.0.0 = "$(semver_bump 0.0.0 major 10)" ]

semver_normalise not-semver || success
[ 1.0.0 = "$(semver_normalise 1)" ]
