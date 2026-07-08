load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_binary")

kt_jvm_binary(
    name = "kotlin",
    srcs = ["Main.kt"],
    main_class = "example.MainKt",
)

build_test(
    name = "kotlin_test",
    targets = [
        ":kotlin",
    ],
)
