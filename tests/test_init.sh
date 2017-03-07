#!/bin/bash

set -eu

bash_pack_components=(
    "a-namespace:$HOME"
)

# shellcheck disable=SC1090
. "$(dirname "$0")/../init.sh" initialise-test

# peek into empty stack; failure
[ "$(bash_pack_component_stack_peek)" = 'bash-pack' ]

# push, peek and test
bash_pack_component_stack_push test1
[ "$(bash_pack_component_stack_peek)" = test1 ]
# push, peek and test
bash_pack_component_stack_push test2
[ "$(bash_pack_component_stack_peek)" = test2 ]

# pop, peek and test
bash_pack_component_stack_pop
[ "$(bash_pack_component_stack_peek)" = test1 ]
bash_pack_component_stack_pop

# pop from empty stack; failure
bash_pack_component_stack_pop || success
