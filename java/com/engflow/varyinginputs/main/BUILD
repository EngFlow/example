load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    deps = [
        "//java/com/engflow/varyinginputs/reader:reader",
        "//java/com/engflow/varyinginputs/writer:writer",
    ],
    data = [
        "//java/com/engflow/varyinginputs/input:input",
    ],
    main_class = "com.engflow.varyinginputs.main.Main",
)
