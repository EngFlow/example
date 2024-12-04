#!/usr/bin/env bash
set -xe

alias buck2="$(realpath buck2-exe)"

# Run cpp example
cd buck2/cpp
buck2 build //:cpp_lib
buck2 test //:cpp_test
cd ..

# Run python example
cd python
buck2 build //main:check_main
buck2 test //hello:hello_unittest_test
cd ..

# Run go example
cd golang
buck2 build //go:hello
buck2 test //go/greeting:greeting_test
cd ..
