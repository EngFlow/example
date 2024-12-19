#!/usr/bin/env bash
set -xe
shopt -s expand_aliases

alias buck2="$(realpath buck2-exe)"

# Run cpp example
cd buck2/cpp
buck2 build --target-platforms //platforms:remote_platform //:cpp_lib
buck2 test --target-platforms //platforms:remote_platform //:cpp_test
cd ..

# Run python example
cd python
buck2 build --target-platforms //platforms:remote_platform //main:check_main
buck2 test --target-platforms //platforms:remote_platform //hello:hello_unittest_test
cd ..

# Run go example
cd golang
buck2 build --target-platforms //platforms:remote_platform //go:hello
buck2 test --target-platforms //platforms:remote_platform //go/greeting:greeting_test
cd ..

# Run rust example
cd rust
buck2 build --remote-only //:main
buck2 test --remote-only //:test
cd ..
