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
#
#
# NOTE
# The following genrules allow for an intensive test on the building system
# as they create thousands of targets to be specified in few lines of code.
# WARNING: Be careful with the number of targets created as it may be
# to much for the current free-tier configuration. 
# Maximum of targets tested so far: 30000 (pdf file)
#
# Change the upper bound of the range and enjoy! 
#

# Text files with size 4KB
[genrule(
 name = "foo_text" + str(x),
 outs = ["foo_text" + str(x) + ".txt"],
 cmd = "echo 'Hello engflow world' > $@",
) for x in range(1,10000)]

# PDF document with size 76KB
[genrule(
 name = "gnu-manifesto" + str(x),
 outs = ["gnu-manifesto" + str(x) + ".pdf"],
 cmd = "cp $(location gnu-manifesto.pdf) $@",
 tools = ["gnu-manifesto.pdf"]
) for x in range(1,1001)]

# Emacs text editor with size 68MB
[genrule(
 name = "emacs" + str(x),
 outs = ["emacs" + str(x) + ".tar.gz"],
 cmd = "cp $(location @emacs//file) $@",
 tools = ["@emacs//file"]
) for x in range(1,1001)]

# Large sized files are hard. Size limit 2GB.
# Ubuntu live with size 1.3GB.  
[genrule(
  name = "ubuntu_20.04_1.3GB" + str(x),
  outs = ["ubuntu_20.04_1.3GB" + str(x) + ".iso"],
  cmd = "cp $(location @ubuntu_20.04_1.3GB//file) $@",
  tools = ["@ubuntu_20.04_1.3GB//file"]
) for x in range(1,3)]
