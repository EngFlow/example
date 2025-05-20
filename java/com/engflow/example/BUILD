load("@rules_java//java:java_library.bzl", "java_library")
load("@rules_java//java:java_test.bzl", "java_test")

package(default_visibility = ["//visibility:public"])

java_library(
    name = "example",
    srcs = ["Example.java"],
)

java_test(
    name = "ExampleTest",
    size = "small",
    srcs = ["ExampleTest.java"],
    deps = [":example"],
)
