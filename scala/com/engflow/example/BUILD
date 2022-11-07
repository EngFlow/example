load("@io_bazel_rules_scala//scala:scala.bzl", "scala_library", "scala_test")

scala_library(
    name = "exampleScala",
    srcs = ["ScalaExample.scala"],
    #main_class = "com.engflow.example.ScalaExample",
)

scala_test(
    name = "exampleScalaTest",
    srcs = ["ScalaExampleTest.scala"],
    deps = [":exampleScala"],
)
