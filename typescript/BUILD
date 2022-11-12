load("@aspect_rules_ts//ts:defs.bzl", "ts_project")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@npm//:defs.bzl", "npm_link_all_packages")

npm_link_all_packages(name = "node_modules")

ts_project(
    name = "typescript",
    srcs = ["main.ts"],
    declaration = True,
    out_dir = ".",
    deps = [
        "//typescript:node_modules/@types/node",
    ],
)

build_test(
    name = "typesctript_test",
    targets = [
        ":typescript",
    ],
)
