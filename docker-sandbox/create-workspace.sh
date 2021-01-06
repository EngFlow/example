#!/bin/bash
#
# Creates a sample Bazel workspace in the current directory.
# The generated BUILD file contains a few Hello World targets.
#
# Usage:
#   ./create-workspace.sh
#   bazel build --config=docker-sandbox //:all

# Change these to use a different build container.
REGISTRY=gcr.io
REPOSITORY=bazel-public/ubuntu2004-java11
DIGEST=sha256:7a4f71955cb0f74ace1e285314933a8c9608f7b20e720abc10cb8107b7093b19

# Create the WORKSPACE file.
# The rbe_autoconfig rule auto-detects C++ and Java toolchains. It takes about a minute.
cat >WORKSPACE <<EOF
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazel_toolchains",
    commit = "109dfdb8a8ffb47a45fa4b4dea58f0b21f708e70",  # Release 3.7.1
    remote = "https://github.com/bazelbuild/bazel-toolchains.git",
)

load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")

rbe_autoconfig(
    name = "engflow_remote_config",
    detect_java_home = True,
    digest = "$DIGEST",
    registry = "$REGISTRY",
    repository = "$REPOSITORY",
)
EOF

# Lock the Bazel version in case you're using Bazelisk.
echo '3.7.2' >.bazelversion

# Create the .bazelrc so you can use "--config=docker-sandbox"
cat >.bazelrc <<EOF
build:docker-sandbox --host_javabase=@engflow_remote_config//java:jdk
build:docker-sandbox --javabase=@engflow_remote_config//java:jdk
build:docker-sandbox --crosstool_top=@engflow_remote_config//cc:toolchain
build:docker-sandbox --spawn_strategy=docker --strategy=Javac=docker --genrule_strategy=docker
build:docker-sandbox --define=EXECUTOR=remote
build:docker-sandbox --experimental_docker_verbose
build:docker-sandbox --experimental_enable_docker_sandbox
build:docker-sandbox --experimental_docker_image=${REGISTRY}/${REPOSITORY}@${DIGEST}
EOF

# Create the Hello World targets.
cat >BUILD <<'EOF'
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
EOF

# Create the Hello World source for C++.
cat >hello.cc <<'EOF'
#include <stdio.h>
int main() {
  printf("hello c++!\n");
  return 0;
}
EOF

# Create the Hello World source for Java.
cat >Hello.java <<'EOF'
public class Hello {
  public static void main(String[] args) {
    System.out.println("Hello Java!");
  }
}
EOF

