genrule(
    name = "hello",
    srcs = ["dep%d" % i for i in range(3)],
    outs = ["hello.txt"],
    cmd = "cat $(SRCS) > $@",
)

[genrule(
    name = "dep%d" % i,
    outs = ["dep%d.txt" % i],
    cmd = "(echo hello %d ; echo \"inside docker: $$(cat /proc/1/cgroup | grep -q 'docker\|lxc' && echo yes || echo no)\" ; echo \"host: $$(hostname)\" ; echo \"date: $$(date)\" ; echo) > $@" % i,
) for i in range(3)]

java_binary(
    name = "hello-java",
    srcs = ["Hello.java"],
    main_class = "Hello",
)

cc_binary(
    name = "hello-cc",
    srcs = ["hello.cc"],
)
