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
) for x in range(1, UPPER_BOUND)]

# Explicitlt specify the following target if
# you want to add more load to the build.
[genrule(
    name = "gnu-manifesto_PDF_76KB" + str(x),
    outs = ["gnu-manifesto" + str(x) + ".pdf"],
    cmd = "cp $(location gnu-manifesto.pdf) $@",
    tags = ["manual"],
    tools = ["gnu-manifesto.pdf"],
) for x in range(1, UPPER_BOUND)]

# Explicitlt specify the following target if
# you want to add more load to the build.
[genrule(
    name = "emacs_TARGZ_68MB" + str(x),
    outs = ["emacs" + str(x) + ".tar.gz"],
    cmd = "cp $(location @emacs//file) $@",
    tags = ["manual"],
    tools = ["@emacs//file"],
) for x in range(1, UPPER_BOUND)]

SYSBOX_EXEC_PROPERTIES = {
    "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-ci/debian12-dind-x64@sha256:1389536c34990e6f49cb38575c2b4f9d08cd3a27e7c3e93c77b7af6260fc5f83",
    "dockerRuntime": "sysbox-runc",
    "Pool": "linux_sysbox_x64",
    "dockerNetwork": "standard",
}

genrule(
    name = "sysbox_cp_no_sudo",
    srcs = ["test_input.txt"],
    outs = ["sysbox_no_sudo.txt"],
    cmd = "cp $(location test_input.txt) $@ && echo 'appended' >> $@",
    exec_properties = SYSBOX_EXEC_PROPERTIES,
    tags = ["manual"],
)

SYSBOX_ROOT_EXEC_PROPERTIES = {
    "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-ci/sysbox-sudo-test@sha256:868e9c2cf3ed714191725630d115c15358097cbe9650ec312de7a2f69cdc80fd",
    "dockerRuntime": "sysbox-runc",
    "dockerRunAsRoot": "True",
    "Pool": "linux_sysbox_x64",
    "dockerNetwork": "standard",
}

genrule(
    name = "sysbox_cp_as_root",
    srcs = ["test_input.txt"],
    outs = ["sysbox_root.txt"],
    cmd = "cp $(location test_input.txt) $@ && echo 'appended' >> $@",
    exec_properties = SYSBOX_ROOT_EXEC_PROPERTIES,
    tags = ["manual"],
)

# Explicitlt specify the following target if
# you want to add more load to the build.
# Be aware that it downloads around 1.3GB.
[genrule(
    name = "ubuntu_20.04_1.3GB" + str(x),
    outs = ["ubuntu_20.04_1.3GB" + str(x) + ".iso"],
    cmd = "cp $(location @ubuntu_20.04_1.3GB//file) $@",
    tags = ["manual"],
    tools = ["@ubuntu_20.04_1.3GB//file"],
) for x in range(1, 2)]
