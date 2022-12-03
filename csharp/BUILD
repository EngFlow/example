load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "csharp.exe",
    srcs = [
        "Main.cs",
    ],
    deps = [
        "@core_sdk_stdlib//:libraryset",
    ],
)
