# Multiple Binary Input Example

## Usage
Set the `NUM_FILES` variable in the BUILD file to the desired input size.

To generate the test files, build the `genbinary` library using the `genrule`:
```sh
bazel build //java/com/engflow/binaryinput:genbinary{1..<NUM_FILES>}
```

Then, the program can be built with the following command:
```sh
bazel build //java/com/engflow/binaryinput:main
```

## How It Works

1. **Generation of Java Binaries:**
    - The `genrule` in the `BUILD` file generates a specified number of Java classes (`Hello1.java`, `Hello2.java`, ..., `HelloN.java`).
    - Each generated class contains a `greetNum` method that prints a unique message.
    - A java library is created for each file (`Hello1.jar`, `Hello2.jar`, ..., `HelloN.jar`).
      
2. **Building the main target:**
   - The previously created libraries are added to the main class as dependencies through a for loop.
   - The consistent naming scheme of the libraries simplifies their inclusion in the build process.

3. **Main Class Execution:**
    - The `Main.java` file in `binaryinput` dynamically loads each generated class using reflection.
    - It then invokes the `greetNum` method of each class, printing the corresponding message.

## Configuration

The number of generated files is controlled by the `NUM_FILES` variable in the `BUILD` file of the `binaryinput` package. Modify this variable to change the number of generated classes and observe the performance impact on Engflow's remote execution and caching service.

## Example

To generate and run the program with 10 input binary files:

1. Set `NUM_FILES` to 10 in `java/com/engflow/binaryinput/BUILD`.
2. Build the `genbinary` library:
   ```sh
   bazel build //java/com/engflow/binaryinput:genbinary{1..10}
   ```
3. Build the `main` binary:
   ```sh
   bazel build //java/com/engflow/binaryinput:main
   ```

This will generate 10 Java classes, build the `genbinary` library, and build the `main` binary. Using `bazel run` will also print messages from each generated class.
