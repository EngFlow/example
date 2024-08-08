py_binary(
    name = "runfiles_demo",
    srcs = ["runfiles_demo.py"],
    deps = ["@rules_python//python/runfiles"],
    data = [
        "//data",
        "@frobozz//:files",
    ],
    args = [
        "$(rlocationpaths //data)",
    ],
    env = {
        "RUNFILE_PATHS": "$(rlocationpaths @frobozz//:files)",
    },
)

genrule(
    name = "runfiles_genrule_demo",
    srcs = [
        "//data:0-foo.txt",
        "@frobozz//:1-gue.txt",
    ],
    outs = ["demo_output.txt"],
    cmd = "RUNFILE_PATHS=\"$(rlocationpath @frobozz//:1-gue.txt)\"" +
          " $(execpath :runfiles_demo) $(rlocationpath //data:0-foo.txt) >$@",
    tools = [":runfiles_demo"],
)
