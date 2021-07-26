# Built from "Dockerfile"
# TODO: edit this value to match your Docker registry, image name, and digest
DOCKER_JDK_PSQL = "docker://gcr.io/YOUR-IMAGE-NAME@sha256:b6ed8f68abd6e23409ee7a500c2c50a8064cea11071ac447a59b88e6afa4c220"


java_test(
    name = "docker-network-test",
    srcs = ["DockerNetworkTest.java"],
    test_class = "DockerNetworkTest",
)

platform(
    name = "platform",
    constraint_values = [
        "@bazel_tools//platforms:x86_64",
        "@bazel_tools//platforms:linux",
    ],
    exec_properties = {
        "container-image": DOCKER_JDK_PSQL,
        "dockerNetwork": "standard",
        "dockerSiblingContainers": "True",
    },
)

java_runtime(
    name = "jdk",
    # JDK base path inside the DOCKER_JDK_PSQL container
    java_home = "/usr/lib/jvm/java-11-openjdk-amd64",
)
