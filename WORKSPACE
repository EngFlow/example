workspace(name = "example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

# Some file dependencies
http_file(
    name = "emacs",
    sha256 = "1439bf7f24e5769f35601dbf332e74dfc07634da6b1e9500af67188a92340a28",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/emacs-28.1.tar.gz",
        "https://mirror.its.dal.ca/gnu/emacs/emacs-28.1.tar.gz",
        "https://mirrors.kernel.org/gnu/emacs/emacs-28.1.tar.gz",
    ],
)

http_file(
    name = "ubuntu_20.04_1.3GB",
    sha256 = "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/ubuntu-20.04.5-live-server-amd64.iso",
        "https://mirror.math.princeton.edu/pub/ubuntu-iso/focal/ubuntu-20.04.5-live-server-amd64.iso",
        "https://mirror.pit.teraswitch.com/ubuntu-releases/focal/ubuntu-20.04.5-live-server-amd64.iso",
    ],
)

http_archive(
    name = "com_engflow_engflowapis",
    sha256 = "8721f7a0ec52c5bc120119aac090eedd671ca3b708652f88b82b44bea2b6c278",
    strip_prefix = "engflowapis-44fcd39598f223e8e5f6c7cbf2f73c870b2a6341",
    urls = [
        "https://github.com/EngFlow/engflowapis/archive/44fcd39598f223e8e5f6c7cbf2f73c870b2a6341.zip",
    ],
)

# https://github.com/bazelbuild/rules_scala/issues/1482
# https://github.com/bazelbuild/bazel-central-registry/issues/522
http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "9a23058a36183a556a9ba7229b4f204d3e68c8c6eb7b28260521016b38ef4e00",
    strip_prefix = "rules_scala-6.4.0",
    url = "https://github.com/bazelbuild/rules_scala/releases/download/v6.4.0/rules_scala-v6.4.0.tar.gz",
)

load("@io_bazel_rules_scala//:scala_config.bzl", "scala_config")

scala_config()

load("@io_bazel_rules_scala//scala:scala.bzl", "scala_repositories")

scala_repositories()

load("@io_bazel_rules_scala//scala:toolchains.bzl", "scala_register_toolchains")

scala_register_toolchains()

load("@io_bazel_rules_scala//testing:scalatest.bzl", "scalatest_repositories", "scalatest_toolchain")

scalatest_repositories()

scalatest_toolchain()

# Abseil Python can be imported through pip_import, but it has native Bazel support too.
http_archive(
    name = "io_abseil_py",
    sha256 = "8a3d0830e4eb4f66c4fa907c06edf6ce1c719ced811a12e26d9d3162f8471758",
    strip_prefix = "abseil-py-2.1.0",
    url = "https://github.com/abseil/abseil-py/archive/refs/tags/v2.1.0.tar.gz",
)
