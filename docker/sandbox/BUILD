load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_java//java:java_binary.bzl", "java_binary")

genrule(
    name = "hello",
    srcs = ["dep%d" % i for i in range(3)],
    outs = ["hello.txt"],
    cmd = "cat $(SRCS) > $@",
)

[genrule(
    name = "dep%d" % i,
    outs = ["dep%d.txt" % i],
    cmd = "(echo hello %d ; echo \"inside docker: $$(cat /proc/1/cgroup | grep -Eq 'docker|lxc' && echo yes || echo no)\" ; echo \"host: $$(hostname)\" ; echo \"date: $$(date)\" ; echo) > $@" % i,
    target_compatible_with = ["@platforms//os:linux"],
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
