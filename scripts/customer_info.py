import os
import yaml

# change this based on customer repo path
repo_path = "/"

# change path for targets as relevant, relative to repo
bazel_target_command = "bazel cquery //java/..."

# change path for actions as relevant, relative to repo
bazel_action_command = "bazel aquery //java/..."


def writeToFile(dict_file):
    print(dict_file)
    with open(r'scripts/customer_info.yaml', 'w') as file:
        yaml.dump(dict_file, file)


if __name__ == '__main__':
    # dictionary with information
    dict_file = {}

    # move to customer project
    os.chdir(repo_path)

    # get bazel version
    bazel_version = os.popen("bazel --version").read()
    print("bazel_version var", bazel_version)
    dict_file["bazel version"] = bazel_version.strip()

    # get targets
    # bazel_target = os.popen(bazel_target_command).read()
    # print("bazel_target var", bazel_target)

    # get actions
    # bazel_action = os.popen(bazel_action_command).read()
    # print("bazel_target var", bazel_action)

    writeToFile(dict_file)
