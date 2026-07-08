load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_perl//perl:perl.bzl", "perl_binary")

perl_binary(
    name = "perl",
    srcs = ["hello_world.pl"],
)

build_test(
    name = "perl_test",
    targets = [
        ":perl",
    ],
)
