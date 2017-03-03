#!/bin/bash

set -eu

# shellcheck disable=SC1090
. "$(dirname "$0")/../init.sh" initialise-test misc array

[ "$(get_named_param a aa=2 a=1 )" = 1 ]
[ "$(get_named_param a aa=YY a=XX)" = XX ]
[ "$(get_named_param a a=)" = '' ]

[ "$(array_join : 1 2 3)" = '1:2:3' ]
[ "$(array_join ': ' 1 2 3)" = '1: 2: 3' ]
[ "$(array_join '' 1 2 3)" = '123' ]

