package(default_visibility = ["//visibility:public"])

java_library(
    name = "class_a",
    srcs = ["ClassA.java"],
    deps = [
        "//java/com/engflow/internship/cycleexample/class_b",
        "//java/com/engflow/internship/cycleexample/interface_a",
    ],
)

java_test(
    name = "class_a_test",
    srcs = ["ClassATest.java"],
    test_class = "cycleexample",
    deps = [
        ":class_a",
        "//java/com/engflow/internship/cycleexample/class_b:class_b",
        "//java/com/engflow/internship/cycleexample/class_c:class_c",
        "//java/com/engflow/internship/cycleexample/interface_a:interface_a",
    ],
)