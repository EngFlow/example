# Varying Inputs Example

## Overview

The goal of this example project is to test the performance of Engflow's remote execution and caching service for different input sizes. The project involves creating a specified number of txt files, each containing 100 random characters, using the `Writer` class, and then reading and printing out their contents with the `Reader` class.

## Project Structure

- `java/com/engflow/varyinginputs/input`: Directory where the generated `.txt` files are saved.
- `java/com/engflow/varyinginputs/main`: Contains the `Main` class which orchestrates the file creation and reading process.
- `java/com/engflow/varyinginputs/reader`: Contains the `Reader` class responsible for reading the files.
- `java/com/engflow/varyinginputs/writer`: Contains the `Writer` class responsible for writing the files.

## Usage

To run the project and specify the number of files to be created, use the following command:

```sh
bazel run //java/com/engflow/varyinginputs/main -- <num_files>
```

Replace `<num_files>` with the desired number of files to be created.

## Example

To create and read 10 files, you would run:

```sh
bazel run //java/com/engflow/varyinginputs/main -- 10
```

This command will:
1. Use the `Writer` class to create 10 files, each containing 100 random characters, in the `input` directory.
2. Use the `Reader` class to read and print the contents of these files.