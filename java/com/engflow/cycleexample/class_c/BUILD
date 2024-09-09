package(default_visibility = ["//visibility:public"])

java_library(
    name = "class_c",
    srcs = ["ClassC.java"],
    visibility = ["//visibility:public"],
    deps = [
        "//java/com/engflow/cycleexample/interface_a",
    ],
)

java_test(
    name = "class_c_test",
    srcs = ["ClassCTest.java"],
    test_class = "cycleexample",
    deps = [
        ":class_c",
        "//java/com/engflow/cycleexample/class_a:class_a",
    ],
)