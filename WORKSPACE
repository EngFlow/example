load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# We use a recent commit hash to get the latest fixes.
git_repository(
    name = "bazel_toolchains",
    commit = "ce6627cc036f45be7f9b0769d06cfe255cfa92e0",
    remote = "https://github.com/bazelbuild/bazel-toolchains.git",
)

load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")
load("@bazel_toolchains//rules/exec_properties:exec_properties.bzl", "create_rbe_exec_properties_dict")

# For now, we use a simple Docker image provided by the Bazel project which
# supports C/C++, Java, and Python. The downside of this image compared to the
# RBE images is that it does not come with configs, so the first build can take
# about a minute to generate them.

rbe_autoconfig(
    name = "engflow_remote_config",
    detect_java_home = True,
    digest = "sha256:d318041b3a16e36550e42c443e856d93710e10252e7111431802fe54b99f2dc9",
    registry = "gcr.io",
    repository = "bazel-public/ubuntu1804-bazel-java11",
    use_legacy_platform_definition = False,
)

