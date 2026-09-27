# Cyclical Dependency Example

## Overview

This project is designed to evaluate and benchmark the performance of EngFlow's remote execution and caching services. It specifically focuses on testing scenarios involving cyclical-like structures in the dependency graph, which are handled through interfaces and constructor injection.

## Purpose

The primary objectives of this project are to:

1. **Generate Performance Data**: Create examples with cyclical-like dependencies to test and gather performance data for EngFlow’s remote caching and execution services.
2. **Benchmark Analysis**: Compare the performance of local versus remote execution and caching to evaluate the efficiency and effectiveness of the service.
3. **Support Automation Development**: Contribute to the development of automation algorithms for resource assignment by providing valuable data on how cyclical dependencies impact performance.

## Project Structure

The project is organized into several packages, each representing different components of the cyclical dependency example:

- `class_a`: Contains `ClassA` which depends on `ClassB` through an interface.
- `class_b`: Contains `ClassB` which implements `InterfaceB` and depends on `ClassC`.
- `class_c`: Contains `ClassC` which implements `InterfaceA` and can be initialized with a reference to `ClassA`.
- `interface_a`: Defines the interface `InterfaceA` implemented by `ClassA` and `ClassC`.
- `interface_b`: Defines the interface `InterfaceB` implemented by `ClassB`.
- `main`: Contains the `Main` class which processes the input file.
- `input`: Contains the input text file used by the `Main` class.

## How the Program Works

The program takes a text input file and recursively prints each word with each class (`ClassA` prints a word, then `ClassB`, and so on) until the string is empty. The input file should be specified in the `data` attribute of the `java_binary` rule in the `BUILD` file.

## How to Run Tests

To run the tests and gather performance data, use the following Bazel command:

```sh
bazel test //java/com/engflow/internship/cycleexample/class_a:class_a_test
