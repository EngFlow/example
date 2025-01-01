load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    deps = [
        "//java/com/engflow/cycleexample/class_a:class_a",
        "//java/com/engflow/cycleexample/class_b:class_b",
        "//java/com/engflow/cycleexample/class_c:class_c",
    ],
    data = [
        "//java/com/engflow/cycleexample/input:input",
    ],
    main_class = "com.engflow.cycleexample.main.Main",
)