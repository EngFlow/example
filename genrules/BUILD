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
load("@bazel_skylib//rules:build_test.bzl", "build_test")

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

# Only test a few to ensure they build, without creating undue load.
build_test(
    name = "foo_TXT_test",
    targets = [
        ":foo_TXT_4KB_1",
    ],
)

# Remote Execution Environment Detection
# These genrules detect system resources where builds are running.

genrule(
    name = "get_cpu_info",
    outs = ["cpu_info.txt"],
    cmd = "(" +
          "echo '=== CPU Info ===' && " +
          "(grep -E 'processor|model name|cpu cores|physical id' /proc/cpuinfo || echo 'cpuinfo unavailable') && " +
          "echo '' && " +
          "echo '=== CPU Count ===' && " +
          "(nproc || echo 'nproc unavailable')" +
          ") 2>&1 | tee $@ >&2",
    tags = ["no-cache"],
)

genrule(
    name = "get_memory_info",
    outs = ["memory_info.txt"],
    cmd = "(" +
          "echo '=== Memory Info ===' && " +
          "(grep -E 'MemTotal|MemAvailable' /proc/meminfo || echo 'meminfo unavailable') && " +
          "echo '' && " +
          "echo '=== Free Memory ===' && " +
          "(free -h || echo 'free unavailable')" +
          ") 2>&1 | tee $@ >&2",
    tags = ["no-cache"],
)

genrule(
    name = "get_system_info",
    outs = ["system_info.txt"],
    cmd = "(" +
          "echo '=== System Info ===' && " +
          "echo '=== Hostname ===' && " +
          "(hostname || echo 'unavailable') && " +
          "echo '' && " +
          "echo '=== Kernel ===' && " +
          "(uname -a || echo 'unavailable') && " +
          "echo '' && " +
          "echo '=== Container/OS ===' && " +
          "(cat /etc/os-release || echo 'unavailable') && " +
          "echo '' && " +
          "echo '=== Disk Space ===' && " +
          "(df -h / || echo 'unavailable')" +
          ") 2>&1 | tee $@ >&2",
    tags = ["no-cache"],
)

# Convenience target to get all info at once
filegroup(
    name = "remote_exec_info",
    srcs = [
        ":get_cpu_info",
        ":get_memory_info",
        ":get_system_info",
    ],
)
