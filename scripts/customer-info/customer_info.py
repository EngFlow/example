import os
import sys
import re
import subprocess

import yaml

# download pylint and add config file from engflow

# to run cd into scripts and run command "python customer_info.py PATH" where path = absolute path to folder with yaml file
# EX: python customer_info.py "/Users/sarahraza/example/scripts/customer-info"

# change path for targets as relevant, relative to repo
bazel_cquery_target_command = ["bazel", "cquery", sys.argv[2]]

# change path for actions by changing //java/ as relevant, relative to repo
bazel_action_summary_command = ["bazel", "aquery", sys.argv[2], "--output=summary"]

# add the names of wanted flag values
# use regular expression instead
relevant_flags = ["test_timeout", "experimental_allow_runtime_deps_on_neverlink",
                  "experimental_limit_android_lint_to_android_constrained_java"]

def execute(args):
    """ Executes an os command """
    try:
        the_process = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as error:
        print("Could not execute os command ", error.returncode, " - ", error, file=sys.stderr)
        sys.exit(1)
    except subprocess.SubprocessError as error:
        print("Could not execute os command ", error.returncode, " - ", error, file=sys.stderr)
        sys.exit(1)
    return the_process.stdout, the_process.stderr

def writeToFile(dict_file):
    path_to_yaml = sys.argv[1] + "/customer_info.yaml"
    with open(path_to_yaml, 'w') as file:
        yaml.dump(dict_file, file)

def extractFlags(bazel_target):
    # creates array of all unique identifiers
    ids = set(re.findall(r'\(.*?\)', bazel_target))

    # creates dictionary mapping unique identifiers to fragments containing all flag information
    config_to_flag = {}
    for id in ids:
        config = id[1:-1]
        bazel_specific_config_command = ["bazel", "config", config]
        config_output, stderr_flag = execute(bazel_specific_config_command)
        config_to_flag[config] = config_output

    # changes dictionary to map from unique identifiers to dictionary containing strings with relevant flag information
    for config, config_output in config_to_flag.items():
        flag_to_val = {}
        for flag in relevant_flags:
            start_index = config_output.find(flag)
            end_index = config_output.find("\n", start_index)
            flag_output = config_output[start_index:end_index]
            if len(flag_output) != 0:
                colon_index = flag_output.find(":")
                flag_to_val[flag_output[:colon_index]] = flag_output[colon_index+2:]
        config_to_flag[config] = flag_to_val

    return config_to_flag


if __name__ == '__main__':
    # dictionary with information
    dict_file = {}

    # move to customer project
    os.chdir(sys.argv[1])

    # get bazel version
    bazel_version_arr = ["bazel", "--version"]
    stdout_version, stderr_version = execute(bazel_version_arr)
    dict_file["bazel version"] = str(stdout_version.strip())

    # get targets
    # NOTE: these targets will be used to obtain the flags
    stdout_target, stderr_target = execute(bazel_cquery_target_command)
    dict_file["bazel targets"] = stdout_target.split("\n")[:-1]

    # get action information
    stdout_action_summary, stderr_action_summary = execute(bazel_action_summary_command)
    bazel_action_summary = stdout_action_summary.split("\n\n")
    formatted_bazel_action_summary = []
    for info in bazel_action_summary:
        formatted_bazel_action_summary.append(info.split("\n"))
    dict_file["bazel action information"] = formatted_bazel_action_summary

    # get flags
    dict_file["relevant bazel flags and values"] = extractFlags(stdout_target)

    writeToFile(dict_file)
