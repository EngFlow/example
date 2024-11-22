#!/usr/bin/env bash
set -x

# Run cpp example
cd buck2/cpp
../../buck2-exe build //:cpp_lib
../../buck2-exe test //:cpp_test
cd ..

# Run python example
cd python
../../buck2-exe build //main:check_main
../../buck2-exe test //hello:hello_unittest_test
cd ..

# Run go example
echo pwd
cd go
../../buck2-exe build //go:hello
../../buck2-exe test //go/greeting:greeting_test
cd ..
