workspace(name = "example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

# Place this first so this version prevails.
http_archive(
    name = "rules_python",
    sha256 = "5868e73107a8e85d8f323806e60cad7283f34b32163ea6ff1020cf27abef6036",
    strip_prefix = "rules_python-0.25.0",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.25.0.tar.gz",
)

http_archive(
    name = "build_bazel_apple_support",
    sha256 = "45d6bbad5316c9c300878bf7fffc4ffde13d620484c9184708c917e20b8b63ff",
    url = "https://storage.googleapis.com/engflow-tools-public/github.com/bazelbuild/apple_support/releases/download/1.8.1/apple_support.1.8.1.tar.gz",
)

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
    sha256 = "8c3b207722e5f97f1c83311582a6c11df99226e65e2471086e296561e57cc954",
    strip_prefix = "rules_jvm_external-5.1",
    url = "https://github.com/bazelbuild/rules_jvm_external/releases/download/5.1/rules_jvm_external-5.1.tar.gz",
)

http_archive(
    name = "com_google_googleapis",
    sha256 = "9ffb1ee529fe3c51ba68746482b542072b95746a65137e375ab65d6529fec38a",
    strip_prefix = "googleapis-522f79ca64f61da52731d51f7ead8696a2a3c61a",
    urls = [
        "https://github.com/googleapis/googleapis/archive/522f79ca64f61da52731d51f7ead8696a2a3c61a.tar.gz",
    ],
)

http_archive(
    name = "com_engflow_engflowapis",
    sha256 = "f2e799573ff21bfb94db5ed773c884f3808fe56d75cf09d60299f5e8e1ecc19d",
    strip_prefix = "engflowapis-0300f7885c4404d26ff494a329a5f2a3fcf67342",
    urls = [
        "https://github.com/EngFlow/engflowapis/archive/0300f7885c4404d26ff494a329a5f2a3fcf67342.zip",
    ],
)

http_archive(
    name = "io_grpc_grpc_java",
    sha256 = "970dcec6c8eb3fc624015f24b98df78f4c857a158fce0617deceafab470b90fc",
    strip_prefix = "grpc-java-1.57.2",
    urls = [
        "https://github.com/grpc/grpc-java/archive/refs/tags/v1.57.2.zip",
    ],
)

http_archive(
    name = "io_bazel_rules_kotlin",
    sha256 = "a630cda9fdb4f56cf2dc20a4bf873765c41cf00e9379e8d59cd07b24730f4fde",
    urls = [
        "https://github.com/bazelbuild/rules_kotlin/releases/download/v1.9.0/rules_kotlin_release.tgz",
    ],
)

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "91585017debb61982f7054c9688857a2ad1fd823fc3f9cb05048b0025c47d023",
    urls = [
        "https://github.com/bazelbuild/rules_go/releases/download/v0.42.0/rules_go-v0.42.0.zip",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "d3fa66a39028e97d76f9e2db8f1b0c11c099e8e01bf363a923074784e451f809",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.33.0/bazel-gazelle-v0.33.0.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.33.0/bazel-gazelle-v0.33.0.tar.gz",
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

# Support for macOS remote execution.
load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

# Loads rules required to compile proto files
http_archive(
    name = "rules_proto_grpc",
    sha256 = "f87d885ebfd6a1bdf02b4c4ba5bf6fb333f90d54561e4d520a8413c8d1fb7beb",
    strip_prefix = "rules_proto_grpc-4.5.0",
    urls = [
        "https://github.com/rules-proto-grpc/rules_proto_grpc/archive/4.5.0.tar.gz",
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
    sha256 = "f8b607d7f2523d06d28703f7ea33b182d138503837b59650cb7fc08f61fed443",
    strip_prefix = "protobuf-376ba2f8bc5273e3c461f39a73bcc6504d70e2f4",
    urls = [
        "https://github.com/protocolbuffers/protobuf/archive/376ba2f8bc5273e3c461f39a73bcc6504d70e2f4.tar.gz",
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
    sha256 = "1f425972c97c99fa5325f74483b97f881cfe3f3809dbfd22d332cd82220eb4a2",
    strip_prefix = "rules_scala-ce54e00a2406b8401483df61119cf00af8599763",
    type = "zip",
    urls = [
        "https://github.com/bazelbuild/rules_scala/archive/ce54e00a2406b8401483df61119cf00af8599763.zip",
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
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load(":deps.bzl", "go_dependencies")

# gazelle:repository_macro deps.bzl%go_dependencies
go_dependencies()

go_rules_dependencies()

go_register_toolchains(version = "1.21.2")

gazelle_dependencies()

load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")

kotlin_repositories()

load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")

kt_register_toolchains()

http_archive(
    name = "aspect_rules_ts",
    sha256 = "4c3f34fff9f96ffc9c26635d8235a32a23a6797324486c7d23c1dfa477e8b451",
    strip_prefix = "rules_ts-1.4.5",
    urls = [
        "https://github.com/aspect-build/rules_ts/archive/refs/tags/v1.4.5.tar.gz",
    ],
)

load("@aspect_rules_ts//ts:repositories.bzl", "rules_ts_dependencies")

rules_ts_dependencies(ts_version_from = "//typescript:package.json")

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
    sha256 = "f1450b5e76ecb81340e2ff50f83b066bebb1fa78dd78bf5d7ece4f3d6d82b5be",
    strip_prefix = "rules_perl-366b6aa76b12056a9e0cc23364686f25dcc41702",
    urls = [
        "https://github.com/bazelbuild/rules_perl/archive/366b6aa76b12056a9e0cc23364686f25dcc41702.zip",
    ],
)

load("@rules_perl//perl:deps.bzl", "perl_register_toolchains", "perl_rules_dependencies")

perl_rules_dependencies()

perl_register_toolchains()

load("@rules_python//python:repositories.bzl", "python_register_toolchains")

python_register_toolchains(
    name = "python_3_11",
    python_version = "3.11.4",
)

load("@python_3_11//:defs.bzl", python_3_11 = "interpreter")
load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "pip_deps",
    python_interpreter_target = python_3_11,
    requirements_lock = "//python:requirements_lock.txt",
)

load("@pip_deps//:requirements.bzl", "install_deps")

install_deps()

# Abseil Python can be imported through pip_import, but it has native Bazel support too.
http_archive(
    name = "io_abseil_py",
    sha256 = "2ab7ce101db02d7a1de48f8157cbd978f00a19bad44828fd213aa69fe352497d",
    strip_prefix = "abseil-py-2.0.0",
    url = "https://github.com/abseil/abseil-py/archive/refs/tags/v2.0.0.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "bf2861de6bf75115288468f340b0c4609cc99cc1ccc7668f0f71adfd853eedb3",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.7.1/rules_swift.1.7.1.tar.gz",
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
