# GENERAL SUMMARY
On a high level, our goal is to improve the customer experience by allowing us to obtain 
the introduction customer information faster. Through running this script, we will recieve 
a yaml file that contains the targets, relevant information about actions (number of total 
actions, set of mnemonics, set of configurations, set of platforms, and set of aspects), the 
bazel version being used, and the values of the relevant bazel flags. 

# RUNNING/EDITING THE SCRIPT 
To run the script, 
1. Navigate to the ```scripts``` folder and then the ```customer-info``` folder
2. run command 
   ```
   python customer_info.py PATH_TO_REPO
   ``` 
   where ```PATH_TO_REPO``` = 
   absolute path to repo
   ```
   python customer_info.py "/Users/sarahraza/example"
   ```
   
To customize the script,
- Change the list of relevant flags by editing the ```relevant_flags``` variable 

# DETAILED SUMMARY
Within the script, the following commands are called:
```
bazel --version
bazel cquery //TARGET
bazel aquery //TARGET
bazel config IDENTIFIER
```

The ```TARGET``` for each command is passed in as the second argument.

The ```IDENTIFIER``` is the unique identifier from each target outputted by the bazel cquery command.

The output after running the script is a yaml file in the customer-info folder. The yaml 
file contains 3 main blocks of information:
- bazel aquery information which contains 5 sub-blocks of information
  1. Total number of actions 
  2. Mnemonics 
  3. Configurations 
  4. Execution Platform
  5. Aspects
  - Example: 
    ```
    bazel aquery information:
        - 47 total actions.
        - 'Mnemonics:  GenProto: 1  TestRunner: 1  GenProtoDescriptorSet: 1  Action: 3  Middleman: 
          3  FileWrite: 3  TemplateExpand: 3  SymlinkTree: 3  SourceSymlinkManifest: 3  
          JavaDeployJar: 3  Turbine: 5  Javac: 8  JavaSourceJar: 10'
        - 'Configurations:  darwin-fastbuild: 47'
        - 'Execution Platforms:  @local_config_platform//:host: 47'
        - 'Aspects:  BazelJavaProtoAspect: 3'
    ```
- bazel cquery targets under which there is a list of targets each of which has a unique 
  identifier at the end between parenthesis 
  - Example:
    ```
    bazel cquery targets: 
    - //java/com/engflow/example:ExampleTest (8a8f93d)
    ```
- bazel flag information in which there is the relevant flag information for each identifier
  - Example: 
    ```
    bazel flag information:
        8a8f93d:
            experimental_allow_runtime_deps_on_neverlink: 'true'
            experimental_limit_android_lint_to_android_constrained_java: 'false'
            test_timeout: '{short=PT1M, moderate=PT5M, long=PT15M, eternal=PT1H}'
        94fc984:
            experimental_allow_runtime_deps_on_neverlink: 'true'
            experimental_limit_android_lint_to_android_constrained_java: 'false'
    ```