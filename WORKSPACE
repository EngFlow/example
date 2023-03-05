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
    sha256 = "179295d042929be29a90b6874a5309231d2f03f129a9554a97e05b9d0bd06adf",
    strip_prefix = "rules_jvm_external-0b81b4dfed12fc079acf5a879de24a01c01dd9f4",
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/0b81b4dfed12fc079acf5a879de24a01c01dd9f4.zip",
)

http_archive(
    name = "com_google_googleapis",
    sha256 = "33d99b8f8b368770c8c2f56e1a421d2b497af15f89334d449ef3c6cccef44f36",
    strip_prefix = "googleapis-00179492fb1d3ceedd9c65b803c6230d59a15d94",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/googleapis-00179492fb1d3ceedd9c65b803c6230d59a15d94.tar.gz",
        "https://github.com/googleapis/googleapis/archive/00179492fb1d3ceedd9c65b803c6230d59a15d94.tar.gz",
    ],
) 

http_archive(
    name = "com_engflow_engflowapis",
    sha256 = "88073a86aa28e6b38dba998b2df7984e176df70044bfadcd663b02273e43c367",
    strip_prefix = "engflowapis-f7e413890de03f8cfd552180340248db1028d440",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/engflowapis-f7e413890de03f8cfd552180340248db1028d440.zip",
        "https://github.com/EngFlow/engflowapis/archive/f7e413890de03f8cfd552180340248db1028d440.zip",
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
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.38.1/rules_go-v0.38.1.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.38.1/rules_go-v0.38.1.zip",
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
    sha256 = "bbe4db93499f5c9414926e46f9e35016999a4e9f6e3522482d3760dc61011070",
    strip_prefix = "rules_proto_grpc-4.2.0",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/rules_proto_grpc-4.2.0.tar.gz",
        "https://github.com/rules-proto-grpc/rules_proto_grpc/archive/4.2.0.tar.gz",
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
    sha256 = "7c8d517e3c594a01213a7d881f2550cfbe8f4d0e5bfa2a68df5c32d103c5bcd0",
    strip_prefix = "protobuf-e83848f09288693d0fe9a71824908bb8f621bd63",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/protobuf-e83848f09288693d0fe9a71824908bb8f621bd63.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/e83848f09288693d0fe9a71824908bb8f621bd63.tar.gz",
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

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.20.1")

load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")

kotlin_repositories()

load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")

kt_register_toolchains()

http_archive(
    name = "aspect_rules_ts",
    sha256 = "5b501313118b06093497b6429f124b973f99d1eb5a27a1cc372e5d6836360e9d",
    strip_prefix = "rules_ts-1.0.2",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/rules_ts-1.0.2.tar.gz",
        "https://github.com/aspect-build/rules_ts/archive/refs/tags/v1.0.2.tar.gz",
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
        "https://storage.googleapis.com/engflow-tools-public/rules_dotnet-0b7ae93fa81b7327a655118da0581db5ebbe0b8d.zip",
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
    sha256 = "8a7a33cb3c81a0677f11b1a9c5384bc9eefaec833913bd313a6494c2783a6046",
    strip_prefix = "rules_perl-022b8daf2bb4836ac7a50e4a1d8ea056a3e1e403",
    urls = [
        "https://storage.googleapis.com/engflow-tools-public/rules_perl-022b8daf2bb4836ac7a50e4a1d8ea056a3e1e403.zip",
        "https://github.com/bazelbuild/rules_perl/archive/022b8daf2bb4836ac7a50e4a1d8ea056a3e1e403.zip",
    ],
)

load("@rules_perl//perl:deps.bzl", "perl_register_toolchains", "perl_rules_dependencies")

perl_rules_dependencies()

perl_register_toolchains()

http_archive(
    name = "rules_python",
    sha256 = "bc4e59e17c7809a5b373ba359e2c974ed2386c58634819ac5a89c0813c15705c",
    strip_prefix = "rules_python-0.15.1",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.15.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "32f95dbe6a88eb298aaa790f05065434f32a662c65ec0a6aabdaf6881e4f169f",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.5.0/rules_swift.1.5.0.tar.gz",
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
