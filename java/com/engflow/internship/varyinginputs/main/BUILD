load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    deps = [
        "//java/com/engflow/internship/varyinginputs/reader",
        "//java/com/engflow/internship/varyinginputs/writer",
    ],
    data = [
        "//java/com/engflow/internship/varyinginputs/input",
    ],
    main_class = "com.engflow.internship.varyinginputs.main.Main",
)