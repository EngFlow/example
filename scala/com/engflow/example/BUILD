load("@rules_scala//scala:scala.bzl", "scala_library", "scala_test")

scala_library(
    name = "exampleScala",
    srcs = ["ScalaExample.scala"],
)

scala_test(
    name = "exampleScalaTest",
    size = "small",
    srcs = ["ScalaExampleTest.scala"],
    deps = [":exampleScala"],
)
