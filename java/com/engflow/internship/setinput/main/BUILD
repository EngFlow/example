load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    deps = [
        "//java/com/engflow/internship/setinput/genreader",
    ],
    data = [
        "//java/com/engflow/internship/setinput/genfile:genfile",
    ],
    main_class = "com.engflow.internship.setinput.main.Main",
)