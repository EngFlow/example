load("@aspect_rules_ts//ts:defs.bzl", "ts_project")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

ts_project(
    name = "typescript",
    srcs = ["main.ts"],
    declaration = True,
    out_dir = ".",
)

build_test(
    name = "typescript_test",
    targets = [
        ":typescript",
    ],
)
