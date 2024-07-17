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
#
# The following genrules are able to produce thousands of targets based
# on the user's input.
# This can be used for stress testing your build infrastructure.
# Change the upper bound of the range and enjoy!
UPPER_BOUND = 10

[genrule(
    name = "foo_TXT_4KB_" + str(x),
    outs = ["foo_text" + str(x) + ".txt"],
    cmd_bash = "echo 'Hello engflow world from bash' > $@",
    cmd_ps = "Set-Content -Path $@ -Value 'Hello engflow world from powershell'",
    exec_properties = {
        "container-image": "docker://YOUR_SYSBOX_DIND_DOCKER_IMAGE",
        "dockerRuntime": "sysbox-runc",
        "Pool": "linux_sysbox_x64", # this can change depending on what pool has sysbox enabled
        "dockerNetwork": "standard",
        # DO NOT ENABLE!!! "dockerSiblingContainers": "True",
        # it will cause the worker to mount /var/run/docker.sock
        # but the goal is to have the container itself run dockerd
        # and this will break it
        # DO NOT ENABLE!!! "dockerPrivileged": "True",
        # sysbox containers will refuse to start
    },
) for x in range(1, UPPER_BOUND)]