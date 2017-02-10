#!/bin/bash

set -eu

. "$(dirname "$0")/../common.sh" initialise-test

[ "$(get_named_param a aa=2 a=1 )" = 1 ]
[ "$(get_named_param a aa=YY a=XX)" = XX ]
[ "$(get_named_param a a=)" = '' ]

[ "$(array_join : 1 2 3)" = '1:2:3' ]
[ "$(array_join ': ' 1 2 3)" = '1: 2: 3' ]
[ "$(array_join '' 1 2 3)" = '123' ]

