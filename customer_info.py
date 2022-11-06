import os
import csv

# change this based on customer repo path
repo_path = "/Users/sarahraza/example"

# change path for targets as relevant, relative to repo
bazel_target_command = "bazel cquery //java/..."

# change path for actions as relevant, relative to repo
bazel_action_command = "bazel aquery //java/..."

if __name__ == '__main__':
    # extract JSON files (for CPUTimes) and InputData from Commits

    # move to customer project
    os.chdir(repo_path)

    # get bazel version
    bazel_version = os.popen("bazel --version").read()
    print("bazel_version var", bazel_version)

    # get targets
    bazel_target = os.popen(bazel_target_command).read()
    print("bazel_target var", bazel_target)

    # get actions
    bazel_action = os.popen(bazel_action_command).read()
    print("bazel_target var", bazel_action)