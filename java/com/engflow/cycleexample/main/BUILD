load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    deps = [
        "//java/com/engflow/cycleexample/class_a",
        "//java/com/engflow/cycleexample/class_b",
        "//java/com/engflow/cycleexample/class_c",
    ],
    main_class = "cycleexample",
)