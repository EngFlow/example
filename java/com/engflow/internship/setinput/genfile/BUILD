NUM_FILES = 16

[genrule(
    name = "benchmark_test_file" + str(x),
    outs = ["benchmark_test_file" + str(x) + ".txt"],
    cmd_bash = "echo 'benchmark test file " + str(x) + "' > $@",
) for x in range(1,NUM_FILES+1)]

filegroup(
    name = "genfile",
    srcs = [":benchmark_test_file" + str(x) for x in range(1,NUM_FILES+1)],
)