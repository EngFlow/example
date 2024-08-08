#!/usr/bin/env python3
#
# Copyright 2024 EngFlow Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

"""Runfiles library demonstration program"""

import os
import os.path
import sys

from python.runfiles import runfiles

_RUNFILES = runfiles.Create()


def print_runfile_info(runfiles_dir, runfile_path):
    """Prints information about a runfile path to standard output.

    Args:
        runfiles_dir:  path to the runfiles directory
        runfile_path:  the runfile path to examine
    """
    actual_path = _RUNFILES.Rlocation(runfile_path)
    runfiles_link = os.path.join(runfiles_dir, runfile_path)
    actual_exists = actual_path is not None and os.path.exists(actual_path)
    print(f'  runfile path:  {runfile_path}')
    print(f'  runfiles link: {runfiles_link}')
    print(f'  link exists:   {os.path.lexists(runfiles_link)}')
    print(f'  actual path:   {actual_path}')
    print(f'  exists:        {actual_exists}\n')


def print_runfiles_information(argv, environ, cwd):
    """Prints information about this program's runfiles to standard output.

    Args:
        argv: list of command line arguments
        environ: dictionary of environment variables
        cwd: current working directory
    """
    runfiles_dir = None

    if 'RUNFILES_DIR' in environ:
        runfiles_dir = environ['RUNFILES_DIR']
        print(f'RUNFILES_DIR:           {runfiles_dir}')

    if 'RUNFILES_MANIFEST_FILE' in environ:
        manifest_file = environ['RUNFILES_MANIFEST_FILE']
        print(f'RUNFILES_MANIFEST_FILE: {manifest_file}')

        if runfiles_dir is None:
            runfiles_dir = manifest_file.removesuffix('_manifest')
            print(f'runfiles dir:           {runfiles_dir}')

    print(f'current working dir:    {cwd}\n')

    if len(argv) != 1:
        print('From the command line arguments:')
        for arg in argv[1:]:
            print_runfile_info(runfiles_dir, arg)

    if 'RUNFILE_PATHS' in environ:
        print('From the RUNFILE_PATHS environment variable:')
        for path in environ['RUNFILE_PATHS'].split(' '):
            print_runfile_info(runfiles_dir, path)


if __name__ == '__main__':
    print_runfiles_information(sys.argv, os.environ, os.getcwd())
