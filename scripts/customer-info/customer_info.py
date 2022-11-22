import os
import sys
import re

import yaml

# to run cd into scripts and run command "python customer_info.py PATH" where path = absolute path to folder with yaml file
# EX: python customer_info.py "/Users/sarahraza/example/scripts/customer-info"

# change path for targets as relevant, relative to repo
bazel_cquery_target_command = "bazel cquery //java/..."

# change path for actions by changing //java/ as relevant, relative to repo
bazel_action_summary_command = "bazel aquery //java/... --output=summary"


def writeToFile(dict_file):
    print(dict_file)
    with open(r'/Users/sarahraza/example/scripts/customer-info/customer_info.yaml', 'w') as file:
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

    # get action count
    bazel_action_summary = (os.popen(bazel_action_summary_command).read()).split("\n\n")
    clean_bazel_action_summary = [item.replace('\n','') for item in bazel_action_summary]
    dict_file["bazel aquery information"] = clean_bazel_action_summary

    writeToFile(dict_file)
