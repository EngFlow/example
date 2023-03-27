workspace(name = "example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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
    name = "rules_jvm_external",
    sha256 = "010a7938640341fa477b4d0687bb499775b503d5d35e34cb5e9792277b9469cf",
    strip_prefix = "rules_jvm_external-6761a7c655cc521a96886275a8d9c8fec3cf8be1",
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/6761a7c655cc521a96886275a8d9c8fec3cf8be1.zip",
)

http_archive(
    name = "com_google_googleapis",
    sha256 = "9fd7843ccc7da3f82b04dbd6549d3219aa256aca545f561f33183d201d04ecb0",
    strip_prefix = "googleapis-3562b6cb373390e07e51888e07916d730befb23c",
    urls = [
        "https://github.com/googleapis/googleapis/archive/3562b6cb373390e07e51888e07916d730befb23c.tar.gz",
    ],
)

http_archive(
    name = "com_engflow_engflowapis",
    sha256 = "53e3f8b495d5c65e8d579063fe03cd7bea14340eecf88936f86ad3be5242f6d9",
    strip_prefix = "engflowapis-b08f7f7c5fb6df9386ba5ac9e0097be25b3b3983",
    urls = [
        "https://github.com/EngFlow/engflowapis/archive/b08f7f7c5fb6df9386ba5ac9e0097be25b3b3983.zip",
    ],
)

http_archive(
    name = "io_grpc_grpc_java",
    sha256 = "d9202c5add9f3d6054748f9aa2505de5717717f5649101bf198be0644186081e",
    strip_prefix = "grpc-java-b09473b0d34f435fe9d2925fa08f3e9079275588",
    urls = [
        "https://github.com/grpc/grpc-java/archive/b09473b0d34f435fe9d2925fa08f3e9079275588.tar.gz",
    ],
)

http_archive(
    name = "io_bazel_rules_kotlin",
    sha256 = "fd92a98bd8a8f0e1cdcb490b93f5acef1f1727ed992571232d33de42395ca9b3",
    urls = [
        "https://github.com/bazelbuild/rules_kotlin/releases/download/v1.7.1/rules_kotlin_release.tgz",
    ],
)

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "dd926a88a564a9246713a9c00b35315f54cbd46b31a26d5d8fb264c07045f05d",
    urls = [
        "https://github.com/bazelbuild/rules_go/releases/download/v0.38.1/rules_go-v0.38.1.zip",
    ],
)

http_archive(
    name = "rules_proto",
    sha256 = "66bfdf8782796239d3875d37e7de19b1d94301e8972b3cbd2446b332429b4df1",
    strip_prefix = "rules_proto-4.0.0",
    urls = [
        "https://github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0.tar.gz",
    ],
)

# Loads rules required to compile proto files
http_archive(
    name = "rules_proto_grpc",
    sha256 = "fb7fc7a3c19a92b2f15ed7c4ffb2983e956625c1436f57a3430b897ba9864059",
    strip_prefix = "rules_proto_grpc-4.3.0",
    urls = [
        "https://github.com/rules-proto-grpc/rules_proto_grpc/archive/4.3.0.tar.gz",
    ],
)

load("@rules_proto_grpc//java:repositories.bzl", rules_proto_grpc_java_repos = "java_repos")

rules_proto_grpc_java_repos()

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")
load("@rules_jvm_external//:defs.bzl", "maven_install")

rules_proto_dependencies()

rules_proto_toolchains()

http_archive(
    name = "com_google_protobuf",
    sha256 = "7790656f0d072f7755d7d2dcd53d4873e826283f7390a9fa420cfe7b44c25458",
    strip_prefix = "protobuf-9b4a3ed9e46b2542185ce6f6e21656955708808f",
    urls = [
        "https://github.com/protocolbuffers/protobuf/archive/9b4a3ed9e46b2542185ce6f6e21656955708808f.tar.gz",
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
        "commons-cli:commons-cli:1.5.0",
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

http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "54b8880b64214a8b5576e3d05cc357cf6508aeda20c563477d78a72f5b138aee",
    strip_prefix = "rules_scala-6b5bf4a8a358008d37f6c24c83a4f2fa7663b72f",
    type = "zip",
    urls = [
        "https://github.com/bazelbuild/rules_scala/archive/6b5bf4a8a358008d37f6c24c83a4f2fa7663b72f.zip",
    ],
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

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.20.2")

load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")

kotlin_repositories()

load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")

kt_register_toolchains()

http_archive(
    name = "aspect_rules_ts",
    sha256 = "8eb25d1fdafc0836f5778d33fb8eaac37c64176481d67872b54b0a05de5be5c0",
    strip_prefix = "rules_ts-1.3.3",
    urls = [
        "https://github.com/aspect-build/rules_ts/archive/refs/tags/v1.3.3.tar.gz",
    ],
)

load("@aspect_rules_ts//ts:repositories.bzl", "rules_ts_dependencies")

rules_ts_dependencies(ts_version_from = "//typescript:package.json")

http_archive(
    name = "rules_nodejs",
    sha256 = "764a3b3757bb8c3c6a02ba3344731a3d71e558220adcb0cf7e43c9bba2c37ba8",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.8.2/rules_nodejs-core-5.8.2.tar.gz"],
)

load("@rules_nodejs//nodejs:repositories.bzl", "DEFAULT_NODE_VERSION", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "node",
    node_version = DEFAULT_NODE_VERSION,
)

load("@aspect_bazel_lib//lib:repositories.bzl", "register_copy_directory_toolchains", "register_copy_to_directory_toolchains")

register_copy_directory_toolchains()

register_copy_to_directory_toolchains()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

http_archive(
    name = "io_bazel_rules_dotnet",
    sha256 = "5098268d2950d658a0ab5558fa9faa590866be7ff1b20a97964b37720f8af2c6",
    strip_prefix = "rules_dotnet-0b7ae93fa81b7327a655118da0581db5ebbe0b8d",
    urls = [
        "https://github.com/bazelbuild/rules_dotnet/archive/0b7ae93fa81b7327a655118da0581db5ebbe0b8d.zip",
    ],
)

load("@io_bazel_rules_dotnet//dotnet:deps.bzl", "dotnet_repositories")

dotnet_repositories()

load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_register_toolchains", "dotnet_repositories_nugets")

dotnet_register_toolchains()

dotnet_repositories_nugets()

http_archive(
    name = "rules_perl",
    sha256 = "47b051ba368f7bf9acdbba73c868128f5f37328092f1e7648511238c630f59f7",
    strip_prefix = "rules_perl-7f10dada09fcba1dc79a6a91da2facc25e72bd7d",
    urls = [
        "https://github.com/bazelbuild/rules_perl/archive/7f10dada09fcba1dc79a6a91da2facc25e72bd7d.zip",
    ],
)

load("@rules_perl//perl:deps.bzl", "perl_register_toolchains", "perl_rules_dependencies")

perl_rules_dependencies()

perl_register_toolchains()

http_archive(
    name = "rules_python",
    sha256 = "ffc7b877c95413c82bfd5482c017edcf759a6250d8b24e82f41f3c8b8d9e287e",
    strip_prefix = "rules_python-0.19.0",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.19.0.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "d25a3f11829d321e0afb78b17a06902321c27b83376b31e3481f0869c28e1660",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.6.0/rules_swift.1.6.0.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()
