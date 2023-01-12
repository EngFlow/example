# Copyright 2021 EngFlow Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Built from "Dockerfile"
# TODO: edit this value to match your Docker registry, image name, and digest
DOCKER_JDK_PSQL = "docker://gcr.io/YOUR-IMAGE-NAME@sha256:b6ed8f68abd6e23409ee7a500c2c50a8064cea11071ac447a59b88e6afa4c220"

java_test(
    name = "docker-network-test",
    srcs = ["DockerNetworkTest.java"],
    test_class = "docker.network.DockerNetworkTest",
)

platform(
    name = "platform",
    constraint_values = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
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
