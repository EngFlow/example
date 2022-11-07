workspace(name = "example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# Some file dependencies
http_file(
    name = "emacs",
    sha256 = "1439bf7f24e5769f35601dbf332e74dfc07634da6b1e9500af67188a92340a28",
    urls = [
        "https://mirror.its.dal.ca/gnu/emacs/emacs-28.1.tar.gz",
        "https://mirrors.kernel.org/gnu/emacs/emacs-28.1.tar.gz",
    ],
)

http_file(
    name = "ubuntu_20.04_1.3GB",
    sha256 = "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4",
    urls = [
        "https://mirror.math.princeton.edu/pub/ubuntu-iso/focal/ubuntu-20.04.5-live-server-amd64.iso",
        "https://mirror.pit.teraswitch.com/ubuntu-releases/focal/ubuntu-20.04.5-live-server-amd64.iso",
    ],
)

http_archive(
    name = "rules_jvm_external",
    sha256 = "c21ce8b8c4ccac87c809c317def87644cdc3a9dd650c74f41698d761c95175f3",
    strip_prefix = "rules_jvm_external-1498ac6ccd3ea9cdb84afed65aa257c57abf3e0a",
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/1498ac6ccd3ea9cdb84afed65aa257c57abf3e0a.zip",
)

http_archive(
    name = "com_google_googleapis",
    sha256 = "25bba87daac3f4f7b9f5cd4632ade645de0d41d9600feccfbe6cbdf0cc8f6ae6",
    strip_prefix = "googleapis-4f46ddcc9349121b27331e5cb5d18c553696a6c3",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/googleapis-4f46ddcc9349121b27331e5cb5d18c553696a6c3.tar.gz",
        "https://github.com/googleapis/googleapis/archive/4f46ddcc9349121b27331e5cb5d18c553696a6c3.tar.gz",
    ],
)

http_archive(
    name = "com_engflow_engflowapis",
    sha256 = "a04a2d2a978355c85dff8b1018d12a8e0a1e6692add9de716fd4d1b7aa1e2a0d",
    strip_prefix = "engflowapis-47aa858b498da13e7863356aaef9c6d05da0a7f2",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/engflowapis-47aa858b498da13e7863356aaef9c6d05da0a7f2.zip",
        "https://github.com/EngFlow/engflowapis/archive/47aa858b498da13e7863356aaef9c6d05da0a7f2.zip",
    ],
)

http_archive(
    name = "io_grpc_grpc_java",
    sha256 = "51bac553d269b97214dbd6aee4e65fc616d8ccd414fc12d708e85979ed4c19b4",
    strip_prefix = "grpc-java-1.45.1",
    urls = ["https://github.com/grpc/grpc-java/archive/v1.45.1.tar.gz"],
)

http_archive(
    name = "rules_proto",
    sha256 = "e017528fd1c91c5a33f15493e3a398181a9e821a804eb7ff5acdd1d2d6c2b18d",
    strip_prefix = "rules_proto-4.0.0-3.20.0",
    urls = [
        "https://github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0-3.20.0.tar.gz",
    ],
)

# Loads rules required to compile proto files
http_archive(
    name = "rules_proto_grpc",
    sha256 = "28724736b7ff49a48cb4b2b8cfa373f89edfcb9e8e492a8d5ab60aa3459314c8",
    strip_prefix = "rules_proto_grpc-4.0.1",
    urls = ["https://github.com/rules-proto-grpc/rules_proto_grpc/archive/4.0.1.tar.gz"],
)

load("@rules_proto_grpc//java:repositories.bzl", rules_proto_grpc_java_repos = "java_repos")

rules_proto_grpc_java_repos()

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")
load("@rules_jvm_external//:defs.bzl", "maven_install")

rules_proto_dependencies()

rules_proto_toolchains()

http_archive(
    name = "com_google_protobuf",
    sha256 = "990e47a163b4057f98b899eca591981b5b735872b58f59b9ead9cecabbb21a2a",
    strip_prefix = "protobuf-21.4",
    urls = [
        "https://github.com/protocolbuffers/protobuf/archive/v21.4.tar.gz",
    ],
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

load("@io_grpc_grpc_java//:repositories.bzl", "IO_GRPC_GRPC_JAVA_ARTIFACTS", "IO_GRPC_GRPC_JAVA_OVERRIDE_TARGETS", "grpc_java_repositories")

grpc_java_repositories()

load("@com_google_googleapis//:repository_rules.bzl", "switched_rules_by_language")

switched_rules_by_language(
    name = "com_google_googleapis_imports",
    java = True,
)

maven_install(
    artifacts = IO_GRPC_GRPC_JAVA_ARTIFACTS + [
        "commons-cli:commons-cli:1.3.1",
        "com.google.oauth-client:google-oauth-client:1.34.1",
    ],
    generate_compat_repositories = True,
    override_targets = IO_GRPC_GRPC_JAVA_OVERRIDE_TARGETS,
    repositories = [
        "https://repo.maven.apache.org/maven2/",
    ],
)

load("@maven//:compat.bzl", "compat_repositories")

compat_repositories()


rules_scala_version = "20220201"

http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "77a3b9308a8780fff3f10cdbbe36d55164b85a48123033f5e970fdae262e8eb2",
    strip_prefix = "rules_scala-%s" % rules_scala_version,
    type = "zip",
    url = "https://github.com/bazelbuild/rules_scala/archive/%s.zip" % rules_scala_version,
)

load("@io_bazel_rules_scala//:scala_config.bzl", "scala_config")

scala_config()

load("@io_bazel_rules_scala//scala:scala.bzl", "scala_repositories")

scala_repositories()

load("@io_bazel_rules_scala//scala:toolchains.bzl", "scala_register_toolchains")

scala_register_toolchains()


