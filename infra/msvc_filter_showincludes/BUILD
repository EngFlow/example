load("@rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

MSVC_PATH = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/cl.exe"

go_library(
    name = "msvc_filter_showincludes_lib",
    srcs = ["msvc_filter_showincludes.go"],
    importpath = "github.com/EngFlow/example/infra/msvc_filter_showincludes",
    visibility = ["//visibility:private"],
    x_defs = {
        "github.com/EngFlow/example/infra/msvc_filter_showincludes.MSVCPath": MSVC_PATH,
    },
)

go_binary(
    name = "msvc_filter_showincludes",
    embed = [":msvc_filter_showincludes_lib"],
    visibility = ["//visibility:public"],
)

go_test(
    name = "msvc_filter_showincludes_test",
    srcs = ["msvc_filter_showincludes_test.go"],
    embed = [":msvc_filter_showincludes_lib"],
    deps = ["@com_github_google_go_cmp//cmp"],
)
