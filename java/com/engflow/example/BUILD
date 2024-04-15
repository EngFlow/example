package(default_visibility = ["//visibility:public"])

java_library(
    name = "example",
    srcs = ["Example.java"],
)

java_test(
    name = "ExampleTest",
    srcs = ["ExampleTest.java"],
    deps = [":example"],
    size = "small",
)
