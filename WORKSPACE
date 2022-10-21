
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
    sha256 = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad",
    urls = [
        "https://mirror.math.princeton.edu/pub/ubuntu-iso/focal/ubuntu-20.04.4-live-server-amd64.iso",
        "https://mirror.pit.teraswitch.com/ubuntu-releases/focal/ubuntu-20.04.4-live-server-amd64.iso",
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


load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

######################
# GOLANG SUPPORT
######################

rules_go_version = "v0.27.0"  # latest @ 2021/05/23

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "69de5c704a05ff37862f7e0f5534d4f479418afc21806c887db544a316f3cb6b",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/{version}/rules_go-{version}.tar.gz".format(version = rules_go_version),
        "https://github.com/bazelbuild/rules_go/releases/download/{version}/rules_go-{version}.tar.gz".format(version = rules_go_version),
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.16")

gazelle_version = "v0.23.0"  # latest @ 2021/05/23

# Gazelle - used for Golang external dependencies
http_archive(
    name = "bazel_gazelle",
    sha256 = "62ca106be173579c0a167deb23358fdfe71ffa1e4cfdddf5582af26520f1c66f",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/bazel-gazelle/releases/download/{version}/bazel-gazelle-{version}.tar.gz".format(version = gazelle_version),
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/{version}/bazel-gazelle-{version}.tar.gz".format(version = gazelle_version),
    ],
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()

load("//3rdparty:go_workspace.bzl", "go_dependencies")

go_dependencies()

#######################
# JAVA SUPPORT
#######################

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

maven_install(
    name = "maven",
    artifacts = [
        "com.google.guava:guava:27.1-jre",
        "junit:junit:4.12",
        "org.hamcrest:hamcrest-library:1.3",
        "org.postgresql:postgresql:42.2.10",
        "org.springframework.boot:spring-boot-autoconfigure:2.1.3.RELEASE",
        "org.springframework.boot:spring-boot-loader:2.1.3.RELEASE",
        "org.springframework.boot:spring-boot-test-autoconfigure:2.1.3.RELEASE",
        "org.springframework.boot:spring-boot-test:2.1.3.RELEASE",
        "org.springframework.boot:spring-boot:2.1.3.RELEASE",
        "org.springframework.boot:spring-boot-starter-web:2.1.3.RELEASE",
        "org.springframework.boot:spring-boot-starter-data-jpa:2.1.3.RELEASE",
        "org.springframework:spring-beans:5.1.5.RELEASE",
        "org.springframework:spring-context:5.1.5.RELEASE",
        "org.springframework:spring-test:5.1.5.RELEASE",
        "org.springframework:spring-web:5.1.5.RELEASE",
        "org.springframework:spring-webmvc:5.1.5.RELEASE",
    ],
    fetch_sources = True,  # Fetch source jars. Defaults to False.
    maven_install_json = "@example//3rdparty:maven_install.json",
    repositories = [
        "https://repo1.maven.org/maven2",
        "https://maven.google.com",
    ],
)

load("@maven//:defs.bzl", "pinned_maven_install")

pinned_maven_install()

######################
# PYTHON SUPPORT
######################
# rules_python_version = "0.13.0"

# http_archive(
#     name = "rules_python",
#     sha256 = "8c8fe44ef0a9afc256d1e75ad5f448bb59b81aba149b8958f02f7b3a98f5d9b4",
#     strip_prefix = "rules_python-0.13.0",
#     url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.13.0.tar.gz",
# )

# load("@rules_python//python:repositories.bzl", "python_register_toolchains")

# python_register_toolchains(
#     name = "python39",
#     # Available versions are listed in @rules_python//python:versions.bzl.
#     python_version = "3.9",
# )

# load("@python39_resolved_interpreter//:defs.bzl", python_interpreter = "interpreter")
# load("@rules_python//python:pip.bzl", "pip_install")

# pip_install(
#     name = "py_deps",
#     python_interpreter_target = python_interpreter,
#     requirements = "//3rdparty:requirements.txt",
# )

# # MYPY SUPPORT
# mypy_integration_version = "0.2.0"  # Latest @ 26th June 2021

# http_archive(
#     name = "mypy_integration",
#     sha256 = "621df076709dc72809add1f5fe187b213fee5f9b92e39eb33851ab13487bd67d",
#     strip_prefix = "bazel-mypy-integration-{version}".format(version = mypy_integration_version),
#     urls = [
#         "https://github.com/thundergolfer/bazel-mypy-integration/archive/refs/tags/{version}.tar.gz".format(version = mypy_integration_version),
#     ],
# )

# load(
#     "@mypy_integration//repositories:repositories.bzl",
#     mypy_integration_repositories = "repositories",
# )

# mypy_integration_repositories()

# load("@mypy_integration//:config.bzl", "mypy_configuration")

# mypy_configuration("//tools/typing:mypy.ini")

# load("@mypy_integration//repositories:deps.bzl", mypy_integration_deps = "deps")

# mypy_integration_deps(
#     "//tools/typing:mypy_version.txt",
#     python_interpreter_target = python_interpreter,
# )

######################
# SCALA SUPPORT
######################

rules_scala_version = "c9cc7c261d3d740eb91ef8ef048b7cd2229d12ec"  # Latest at 2021/05/23

http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "8887906c9698a63f7ebf30498050fee695d7fdc70b0ee084fece549cbe922159",
    strip_prefix = "rules_scala-%s" % rules_scala_version,
    type = "zip",
    url = "https://github.com/bazelbuild/rules_scala/archive/%s.zip" % rules_scala_version,
)

# Stores Scala version and other configuration
# 2.12 is a default version, other versions can be use by passing them explicitly:
# scala_config(scala_version = "2.11.12")
load("@io_bazel_rules_scala//:scala_config.bzl", "scala_config")

scala_config()

load("@io_bazel_rules_scala//scala:scala.bzl", "scala_repositories")

scala_repositories()

load("@io_bazel_rules_scala//scala:toolchains.bzl", "scala_register_toolchains")

scala_register_toolchains()

# optional: setup ScalaTest toolchain and dependencies
load("@io_bazel_rules_scala//testing:scalatest.bzl", "scalatest_repositories", "scalatest_toolchain")

scalatest_repositories()

scalatest_toolchain()

# Load dependencies managed by bazel-deps
load("//3rdparty:jvm_workspace.bzl", scala_deps = "maven_dependencies")
load("//3rdparty:target_file.bzl", "build_external_workspace")

build_external_workspace(name = "3rdparty_jvm")

scala_deps()

#######################################
# TYPESCRIPT / NODEJS SUPPORT
#######################################

rules_nodejs_version = "1.7.0"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "84abf7ac4234a70924628baa9a73a5a5cbad944c4358cf9abdb4aab29c9a5b77",
    urls = [
        "https://github.com/bazelbuild/rules_nodejs/releases/download/{version}/rules_nodejs-{version}.tar.gz".format(
            version = rules_nodejs_version,
        ),
    ],
)

load("@build_bazel_rules_nodejs//:index.bzl", "yarn_install")

yarn_install(
    name = "npm",
    package_json = "//3rdparty/typescript:package.json",
    yarn_lock = "//3rdparty/typescript:yarn.lock",
)

load("@npm//:install_bazel_dependencies.bzl", "install_bazel_dependencies")

install_bazel_dependencies()

# Set up TypeScript toolchain
load("@npm_bazel_typescript//:index.bzl", "ts_setup_workspace")

ts_setup_workspace()

######################
# CODE DISTRIBUTION
######################

# graknlabs_bazel_distribution_version = "bc6d555ca29ec75de9b9f16e1537bb8b2862c51a"  # Latest at 2021/05/24

# http_archive(
#     name = "graknlabs_bazel_distribution",
#     sha256 = "4bba7dc36934c6b9a34a049a4f1657f40faaf127f734cda71ca727273a54c64f",
#     strip_prefix = "bazel-distribution-{version}".format(version = graknlabs_bazel_distribution_version),
#     urls = ["https://github.com/vaticle/bazel-distribution/archive/{version}.zip".format(version = graknlabs_bazel_distribution_version)],
# )

# pip_install(
#     name = "graknlabs_bazel_distribution_pip",
#     requirements = "@graknlabs_bazel_distribution//pip:requirements.txt",
# )

######################
# OTHER
######################

# buildifier BUILD file linter
http_archive(
    name = "com_github_bazelbuild_buildtools",
    strip_prefix = "buildtools-master",
    url = "https://github.com/bazelbuild/buildtools/archive/master.zip",
)

linting_system_version = "7f8b336f4e9dbfcfd4fe6a1406047e72abc059aa"

# Source code linting system
# ⚠️ Currently in ALPHA as at 2020/12/12
http_archive(
    name = "linting_system",
    sha256 = "fc9b5c78aff9836b5c7abe6ed24f9ad549fbec642bb43e27584fcf416991f786",
    strip_prefix = "bazel-linting-system-{version}".format(version = linting_system_version),
    url = "https://github.com/thundergolfer/bazel-linting-system/archive/{version}.zip".format(version = linting_system_version),
)

load("@linting_system//repositories:repositories.bzl", "repositories")

repositories()

load("@linting_system//repositories:go_repositories.bzl", "go_deps")

go_deps()
