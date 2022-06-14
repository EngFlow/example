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
 cmd = "echo 'Hello engflow world' > $@",
) for x in range(1,UPPER_BOUND)]

[genrule(
 name = "gnu-manifesto_PDF_76KB" + str(x),
 outs = ["gnu-manifesto" + str(x) + ".pdf"],
 cmd = "cp $(location gnu-manifesto.pdf) $@",
 tools = ["gnu-manifesto.pdf"]
) for x in range(1,UPPER_BOUND)]

[genrule(
 name = "emacs_TARGZ_68MB" + str(x),
 outs = ["emacs" + str(x) + ".tar.gz"],
 cmd = "cp $(location @emacs//file) $@",
 tools = ["@emacs//file"]
) for x in range(1,UPPER_BOUND)]

[genrule(
  name = "ubuntu_20.04_1.3GB" + str(x),
  outs = ["ubuntu_20.04_1.3GB" + str(x) + ".iso"],
  cmd = "cp $(location @ubuntu_20.04_1.3GB//file) $@",
  tools = ["@ubuntu_20.04_1.3GB//file"]
) for x in range(1,2)]
