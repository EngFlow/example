# Copyright 2022 EngFlow Inc. All rights reserved.
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

sh_test(
    name = "check_docker",
    srcs = ["check_docker.sh"],
    exec_properties = {
        # Replace the container-image below to use the one you created.
        "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-ci/debian12-dind-x64@sha256:e9715893e041427c283808db96760634b47b276d35bef4fc2af3990553f94262",
        "dockerRuntime": "sysbox-runc",
        "Pool": "ci_sysbox_x64", # this can change depending on what pool has sysbox enabled
        "dockerNetwork": "standard",
        # DO NOT ENABLE!!! "dockerSiblingContainers": "True",
        # it will cause the worker to mount /var/run/docker.sock
        # but the goal is to have the container itself run dockerd
        # and this will break it
        # DO NOT ENABLE!!! "dockerPrivileged": "True",
        # sysbox containers will refuse to start
    },
    tags = ["manual"]
)
