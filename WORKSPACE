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
    sha256 = "179295d042929be29a90b6874a5309231d2f03f129a9554a97e05b9d0bd06adf",
    strip_prefix = "rules_jvm_external-0b81b4dfed12fc079acf5a879de24a01c01dd9f4",
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/0b81b4dfed12fc079acf5a879de24a01c01dd9f4.zip",
)

http_archive(
    name = "com_google_googleapis",
    sha256 = "c1a2e6affde3110cf2064bdf40fc935364de7c9724dd3505ca68588f803cb4a9",
    strip_prefix = "googleapis-d1c447b6c522355799cd076c74dee6e484b96cdf",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/googleapis-d1c447b6c522355799cd076c74dee6e484b96cdf.tar.gz",
        "https://github.com/googleapis/googleapis/archive/d1c447b6c522355799cd076c74dee6e484b96cdf.tar.gz",
    ],
)

http_archive(
    name = "com_engflow_engflowapis",
    sha256 = "2c4826ea9825b3e3956bba65469020ffff8a2178694c33eba86bf4d97a2a256a",
    strip_prefix = "engflowapis-b8ecd7487fca4764a393037d5d74f67239694fc0",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/engflowapis-b8ecd7487fca4764a393037d5d74f67239694fc0.zip",
        "https://github.com/EngFlow/engflowapis/archive/b8ecd7487fca4764a393037d5d74f67239694fc0.zip",
    ],
)

http_archive(
    name = "io_grpc_grpc_java",
    sha256 = "da84dd3e39bf647997d57ca2cebbc1d6d643ccdeb16197b36d255a4dd17f13bb",
    strip_prefix = "grpc-java-775d79b0eb1717f381ebb698f5302db702f6200c",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/grpc-java-775d79b0eb1717f381ebb698f5302db702f6200c.tar.gz",
        "https://github.com/grpc/grpc-java/archive/775d79b0eb1717f381ebb698f5302db702f6200c.tar.gz",
    ],
)

http_archive(
    name = "rules_proto",
    sha256 = "e017528fd1c91c5a33f15493e3a398181a9e821a804eb7ff5acdd1d2d6c2b18d",
    strip_prefix = "rules_proto-4.0.0-3.20.0",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/rules_proto-4.0.0-3.20.0.tar.gz",
        "https://github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0-3.20.0.tar.gz",
    ],
)

# Loads rules required to compile proto files
http_archive(
    name = "rules_proto_grpc",
    sha256 = "1d5223a1c7d3b41f07bb43602699dcb852ab01ffc68a55ea031f71ace4fd7daf",
    strip_prefix = "rules_proto_grpc-58f568397f3707e072c3e94493c380edea04337c",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/58f568397f3707e072c3e94493c380edea04337c.tar.gz",
        "https://github.com/rules-proto-grpc/rules_proto_grpc/archive/58f568397f3707e072c3e94493c380edea04337c.tar.gz",
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
    sha256 = "f6db31d70e2e0a3722b9eec50393f3c02ab88769dc682a30d78afc72e3288248",
    strip_prefix = "protobuf-4ac90bbb69719ebdbf1dd1c8450daa2cf4bbd313",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/protobuf-4ac90bbb69719ebdbf1dd1c8450daa2cf4bbd313.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/4ac90bbb69719ebdbf1dd1c8450daa2cf4bbd313.tar.gz",
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
    sha256 = "ebc2b00d599a73e62743bee5e4b11e5e94f35692b869d49f31b04faec380c16c",
    strip_prefix = "rules_scala-73f5d1a7da081c9f5160b9ed7ac745388af28e23",
    type = "zip",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/rules_scala-73f5d1a7da081c9f5160b9ed7ac745388af28e23.zip",
        "https://github.com/bazelbuild/rules_scala/archive/73f5d1a7da081c9f5160b9ed7ac745388af28e23.zip",
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

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "1105a42cfbaf12dba09be6aa3a9c340db1e5b655b07be5ac9cded1ee9ffc0f08",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/79e00373e1a9dc6363ae278a73264b39da44ad55.zip",
        "https://github.com/bazelbuild/rules_go/archive/79e00373e1a9dc6363ae278a73264b39da44ad55.zip",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.19.3")

http_archive(
    name = "io_bazel_rules_kotlin",
    sha256 = "a57591404423a52bd6b18ebba7979e8cd2243534736c5c94d35c89718ea38f94",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/9e03fd92eebec869b9c092272b421550a3c1c1f5.tar.gz",
        "https://github.com/bazelbuild/rules_kotlin/releases/download/v1.6.0/rules_kotlin_release.tgz",
    ],
)

load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")

kotlin_repositories()

load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")

kt_register_toolchains()

http_archive(
    name = "aspect_rules_ts",
    sha256 = "137cd6b897eb88e6f0f00e70eeaaa5bfcaf29177c6f59d3e2be2aed5c01239fb",
    strip_prefix = "rules_ts-9e03fd92eebec869b9c092272b421550a3c1c1f5",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/9e03fd92eebec869b9c092272b421550a3c1c1f5.tar.gz",
        "https://github.com/aspect-build/rules_ts/archive/9e03fd92eebec869b9c092272b421550a3c1c1f5.tar.gz",
    ],
)

load("@aspect_rules_ts//ts:repositories.bzl", "rules_ts_dependencies")

rules_ts_dependencies(ts_version_from = "//typescript:package.json")

load("@rules_nodejs//nodejs:repositories.bzl", "DEFAULT_NODE_VERSION", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "node",
    node_version = DEFAULT_NODE_VERSION,
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

http_archive(
    name = "io_bazel_rules_dotnet",
    sha256 = "5098268d2950d658a0ab5558fa9faa590866be7ff1b20a97964b37720f8af2c6",
    strip_prefix = "rules_dotnet-0b7ae93fa81b7327a655118da0581db5ebbe0b8d",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/0b7ae93fa81b7327a655118da0581db5ebbe0b8d.zip",
        "https://github.com/bazelbuild/rules_dotnet/archive/0b7ae93fa81b7327a655118da0581db5ebbe0b8d.zip",
    ],
)

load("@io_bazel_rules_dotnet//dotnet:deps.bzl", "dotnet_repositories")

dotnet_repositories()

load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_register_toolchains", "dotnet_repositories_nugets")

dotnet_register_toolchains()

dotnet_repositories_nugets()
