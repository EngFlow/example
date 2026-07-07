load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "csharp.exe",
    srcs = [
        "Main.cs",
    ],
    target_frameworks = [
        "net8.0",
    ],
)

build_test(
    name = "csharp_test",
    targets = [
        ":csharp.exe",
    ],
)
