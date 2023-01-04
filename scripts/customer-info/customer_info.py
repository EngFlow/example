import os
import sys
import re
import subprocess

import yaml

# download pylint and add config file from engflow

if len(sys.argv) < 2:
    print("Please provide the following arguments: file path to repo."
          "Check README for further information.")
    quit()

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
            check=True,
            timeout=10
        )
    except subprocess.TimeoutExpired as error:
        print("The command '{}' timed out after {} seconds".format(error.cmd, error.timeout), file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as error:
        print("Could not execute os command ", error.returncode, " - ", error, file=sys.stderr)
        sys.exit(1)
    except subprocess.SubprocessError as error:
        print("Could not execute os command ", error.returncode, " - ", error, file=sys.stderr)
        sys.exit(1)
    return the_process.stdout, the_process.stderr

def writeToFile(dict_file, path_to_customer_info):
    '''Takes in dictionary mapping category of data to value and writes to yaml file'''
    path_to_yaml = path_to_customer_info + "/customer_info.yaml"
    with open(path_to_yaml, 'w') as file:
        yaml.dump(dict_file, file)

def extractFlags(bazel_target):
    '''Takes in list of targets from cquery and returns flags for the targets'''

    # creates array of all unique identifiers
    ids = set(re.findall(r'\(.*?\)', bazel_target))

    print(bazel_target)

    # creates dictionary mapping unique identifiers to fragments containing all flag information
    print("Extracting all flags...")
    config_to_flag = {}
    for id in ids:
        config = id[1:-1] # removes parenthesis
        bazel_specific_config_command = ["bazel", "config", config]
        config_output, stderr_flag = execute(bazel_specific_config_command)
        config_to_flag[config] = config_output

    # changes dictionary to map from unique identifiers to dictionary containing strings with relevant flag information
    print("Shortening to relevant flags and saving to file...")
    new_config_to_flag = {}
    for config, config_output in config_to_flag.items():
        flag_to_val = {}
        for flag in relevant_flags:
            start_index = config_output.find(flag)
            end_index = config_output.find("\n", start_index)
            flag_output = config_output[start_index:end_index]
            if len(flag_output) != 0:
                colon_index = flag_output.find(":")
                flag_to_val[flag_output[:colon_index]] = flag_output[colon_index+2:]
            new_config_to_flag[config] = flag_to_val

    return new_config_to_flag

def getPotentialCommandFilePaths():
    '''Returns potential file paths as targets to execute bazel commands'''
    os.chdir(sys.argv[1])
    bazel_query_command = ["bazel", "query", "..."]
    stdout_version, stderr_version = execute(bazel_query_command)
    all_targets = stdout_version.split('\n')
    potential_targets = set()
    for target in all_targets:
        third_slash_index = target.find("/", 2)
        colon_index = target.find(":")
        if third_slash_index > 0:
            potential_targets.add(target[:third_slash_index] + "/...")
        elif colon_index > 0:
            potential_targets.add(target[:colon_index] + "/...")
    return potential_targets



if __name__ == '__main__':
    '''Executes bazel commands for each file path, saving targets, action information, and flags to yaml file'''
    potential_targets = getPotentialCommandFilePaths()

    # dictionary with all information to put in yaml file
    dict_file = {}
    # dictionary with all bazel action information
    dict_bazel_actions = {}
    # dictionary with all config to flag information
    dict_flag_information = []

    # path to customer-info directory
    path_to_customer_info = sys.argv[1] + "/scripts/customer-info"

    # move to customer project
    os.chdir(path_to_customer_info)

    # get bazel version
    print("Extracting bazel version information...")
    bazel_version_arr = ["bazel", "--version"]
    stdout_version, stderr_version = execute(bazel_version_arr)
    print("Saving in file...")
    dict_file["bazel version"] = str(stdout_version.strip())

    for target in potential_targets:

        # get targets
        # NOTE: these targets will be used to obtain the flags
        bazel_cquery_target_command = ["bazel", "cquery", target]
        print("Extracting bazel targets...")
        try:
            stdout_target, stderr_target = execute(bazel_cquery_target_command)
        except SystemExit:
            continue

        # get action information
        bazel_action_summary_command = ["bazel", "aquery", target, "--output=summary"]
        print("Extracting bazel action information based on targets...")
        try:
            stdout_action_summary, stderr_action_summary = execute(bazel_action_summary_command)
            bazel_action_summary = stdout_action_summary.split("\n\n")
            formatted_bazel_action_summary = []
            for info in bazel_action_summary:
                formatted_bazel_action_summary.append(info.split("\n"))

            # setting or updating action count to dict
            num_actions = re.findall(r'\d+', formatted_bazel_action_summary[0][0])
            dict_bazel_actions.setdefault("total_actions", []).append(int(num_actions[0]))

            # adding other information to dictionary
            for info in formatted_bazel_action_summary[1:]:
                if info[0] in dict_bazel_actions:
                    dict_bazel_actions[info[0]][target] = info[1:]
                else:
                    dict_bazel_actions[info[0]] = {}
                    dict_bazel_actions[info[0]][target] = info[1:]

        except SystemExit:
            continue

        # get flags
        print("Extracting relevant flag information...")
        new_dict = extractFlags(stdout_target)
        dict_flag_information.append(new_dict)

        # write targets, action, and flag to main dictionary
        print("Saving targets in file...")
        dict_file.setdefault("bazel_targets", []).append(stdout_target.split("\n")[:-1])
        print("Saving action information in file...")
        dict_file.setdefault("bazel_action_information", []).append(dict_bazel_actions)
        print("Saving flag information in file...")
        dict_file.setdefault("relevant bazel flags and values", []).append(dict_flag_information)

    # sums all the individual action count and saves that value
    sum_total_actions = sum(dict_file['bazel_action_information'][0]['total_actions'])
    dict_file['bazel_action_information'][0]['total_actions'] = sum_total_actions

    # write everything to the yaml file
    writeToFile(dict_file, path_to_customer_info)
