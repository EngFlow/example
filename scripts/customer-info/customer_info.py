import os
import sys

import yaml

# to run cd into scripts and run command "python customer_info.py PATH" where path = absolute path to yaml file
# EX: python customer_info.py "/Users/sarahraza/example/scripts/"

# change path for targets as relevant, relative to repo
bazel_cquery_target_command = "bazel cquery //java/..."

# change path for actions as relevant, relative to repo
bazel_action_command = "bazel aquery //java/..."


def writeToFile(dict_file):
    print(dict_file)
    with open(r'customer_info.yaml', 'w') as file:
        yaml.dump(dict_file, file)


if __name__ == '__main__':
    # dictionary with information
    dict_file = {}

    # move to customer project
    os.chdir(sys.argv[1])

    # get bazel version
    bazel_version = os.popen("bazel --version").read()
    dict_file["bazel version"] = str(bazel_version.strip())

    # get targets
    bazel_target = os.popen(bazel_cquery_target_command).read()
    dict_file["bazel cquery targets"] = bazel_target

    writeToFile(dict_file)
