load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    deps = [
        "//java/com/engflow/internship/setinput/genreader",
    ],
    data = glob(["java/com/engflow/internship/setinput/genfile/*.txt"]),
    main_class = "com.engflow.internship.setinput.main.Main",
)