# Multiple Binary Input Example

## Overview

The example contains a `genrule` that generates a specified number of Java binaries for the `genbinary` Java library, which are then listed as dependencies in the main binary. In this way we can study the relation between number of inputs (dependendencies) and build time.

## Project Structure

- `java/com/engflow/binaryinput/Main.java`: Main class that dynamically loads and invokes methods from generated classes.
- `java/com/engflow/binaryinput/BUILD`: Bazel build file for the `main` java binary and the `genbinary` library.

## Usage

To generate the test files, build the `genbinary` library using the `genrule`:
```sh
bazel build //java/com/engflow/binaryinput:genbinary
```

Then, the program can be run with the following command:
```sh
bazel run //java/com/engflow/binaryinput:main
```

## How It Works

1. **Generation of Java Binaries:**
    - The `genrule` in the `BUILD` file generates a specified number of Java classes (`Hello1.java`, `Hello2.java`, ..., `HelloN.java`).
    - Each generated class contains a `greetNum` method that prints a unique message.

2. **Main Class Execution:**
    - The `Main.java` file in `binaryinput` dynamically loads each generated class using reflection.
    - It then invokes the `greetNum` method of each class, printing the corresponding message.

## Configuration

The number of generated files is controlled by the `NUM_FILES` variable in the `BUILD` file of the `binaryinput` package. Modify this variable to change the number of generated classes and observe the performance impact on Engflow's remote execution and caching service.

## Example

To generate and run the program with 10 input binary files:

1. Set `NUM_FILES` to 10 in `java/com/engflow/binaryinput/BUILD`.
2. Build the `genbinary` library:
   ```sh
   bazel build //java/com/engflow/binaryinput:genbinary
   ```
3. Run the `main` binary:
   ```sh
   bazel run //java/com/engflow/binaryinput:main
   ```

This will generate 10 Java classes, build the `genbinary` library, and run the `main` binary, which will print messages from each generated class.