package(default_visibility = ["//visibility:public"])

java_library(
  name = "example",
  srcs = glob(["Example.java"]),
)

java_test(
  name = "ExampleTest",
  srcs = glob(["ExampleTest.java"]),
  deps = [":example"],
)
