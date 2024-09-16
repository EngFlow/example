package(default_visibility = ["//visibility:public"])

java_library(
    name = "class_b",
    srcs = ["ClassB.java"],
    deps = [
        "//java/com/engflow/internship/cycleexample/class_c",
        "//java/com/engflow/internship/cycleexample/interface_b",
    ],
)

java_test(
    name = "class_b_test",
    srcs = ["ClassBTest.java"],
    test_class = "com.engflow.internship.cycleexample.class_b.ClassBTest",
    deps = [
        ":class_b",
        "//java/com/engflow/internship/cycleexample/class_c:class_c",
        "//java/com/engflow/internship/cycleexample/interface_b:interface_b",
    ],
)