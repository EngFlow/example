py_binary(
    name = "runfiles_demo",
    srcs = ["runfiles_demo.py"],
    deps = ["@rules_python//python/runfiles"],
    data = [
        "//data",
        "@frobozz//:files",
    ],
    # Demonstrate using rlocationpaths in "args". If you prefer, you can put
    # all of these in "env".
    args = [
        "$(rlocationpaths //data)",
    ],
    # Demonstrate using rlocationpaths in "env". If you prefer, you can put
    # all of these in "args".
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
    # Demonstrate passing rlocationpaths using both an environment variable and
    # a command line argument. In practice, you may choose to use only one
    # method or the other.
    cmd = "RUNFILE_PATHS=\"$(rlocationpath @frobozz//:1-gue.txt)\"" +
          " $(execpath :runfiles_demo) $(rlocationpath //data:0-foo.txt) >$@",
    tools = [":runfiles_demo"],
)
