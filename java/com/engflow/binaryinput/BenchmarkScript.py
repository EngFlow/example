import subprocess
import uuid
import csv
import os
import json

# Modify the BUILD file to define the number of files
def modify_build_file(num_files):
    with open('BUILD', 'r') as file:
        lines = file.readlines()

    with open('BUILD', 'w') as file:
        for line in lines:
            if line.startswith('NUM_FILES'):
                file.write(f'NUM_FILES = {num_files}\n')
            else:
                file.write(line)

def run_bazel_command(command):
    subprocess.run(command, check=True)

# Read the Bazel profile data
def analyze_bazel_profile(profile_path):
    with open(profile_path, 'r') as file:
        profile_data = json.load(file)
    return profile_data

# Extract the critical time and total run time from the Bazel profile data
def extract_times(profile_data):
    critical_time = 0
    start_time = None
    end_time = None

    # Iterate through the events in the profile data to extract the critical time and total run time
    for event in profile_data['traceEvents']:
        if event.get('cat') == 'critical path component':
            critical_time += event['dur'] / 1000000.0  # Convert microseconds to seconds
        if event.get('cat') == 'build phase marker' and event['name'] == 'Launch Blaze':
            start_time = event['ts'] / 1000000.0  # Convert microseconds to seconds
        if event.get('cat') == 'build phase marker' and event['name'] == 'Complete build':
            end_time = event['ts'] / 1000000.0  # Convert microseconds to seconds

    # Calculate the total run time
    total_run_time = end_time - start_time if start_time and end_time else None

    return critical_time, total_run_time


def main():
    num_files = int(input("Enter the number of files: "))
    execution_type = input("Enter the execution type (local/remote): ")
    iterations = int(input("Enter the number of iterations: "))

    modify_build_file(num_files)

    results = []

    # Path to the Bazel profile data
    # Using an absolute path to avoid issues with the Bazel workspace
    profile_path = os.path.abspath('profile.json')

    for i in range(iterations):
        if execution_type == 'local':
            # Clear the Bazel cache
            run_bazel_command(['bazel', 'clean', '--expunge'])
            # Generate the input files
            targets = [f':genbinary{j}' for j in range(1, num_files + 1)]
            run_bazel_command(['bazel', 'build'] + targets)
            # Build the main target and generate the Bazel profile data
            run_bazel_command(['bazel', 'build', f'--profile={profile_path}', ':main'])
        elif execution_type == 'remote':
            # Generate a unique key for the cache silo
            key = str(uuid.uuid4())
            # Generate the input files
            targets = [f':genbinary{j}' for j in range(1, num_files + 1)]
            run_bazel_command(['bazel', 'build', '--config=engflow', f'--remote_default_exec_properties=cache-silo-key={key}'] + targets)
            # Build the main target and generate the Bazel profile data
            run_bazel_command(['bazel', 'build', '--config=engflow', f'--profile={profile_path}', f'--remote_default_exec_properties=cache-silo-key={key}', ':main'])

        profile_output = analyze_bazel_profile(profile_path)
        critical_time, total_run_time = extract_times(profile_output)
        results.append((critical_time, total_run_time))

    # Write the results to a CSV file
    #with open(f'results{num_files}.csv', 'w', newline='') as csvfile:
    #    writer = csv.writer(csvfile)
    #    writer.writerow(['Critical Time', 'Total Run Time'])
    #    writer.writerows(results)

    critical_times = [result[0] for result in results]
    total_run_times = [result[1] for result in results]

    print(results)

    # Calculate the highest critical time and total run time
    critical_time_max = max(critical_times)
    total_run_time_max = max(total_run_times)

    print(f'Highest Critical Time: {critical_time_max}')
    print(f'Highest Total Run Time: {total_run_time_max}')

if __name__ == '__main__':
    main()