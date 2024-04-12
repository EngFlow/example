cc_binary(
    name = "cpp",
    srcs = ["main.cc"],
    deps = [":cpp_lib"],
)

cc_library(
    name = "cpp_lib",
    srcs = [
        "hello.cc",
        "hello.h",
    ],
)

cc_test(
    name = "cpp_test",
    srcs = ["hello_test.cc"],
    deps = [":cpp_lib"],
    size = "small",
)
