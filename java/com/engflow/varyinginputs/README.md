# Varying Inputs Example

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
