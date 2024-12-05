load("@rules_java//java:defs.bzl", "java_binary", "java_library")

NUM_FILES = 100

# Generates a number of java files based on the value of NUM_FILES
# Each file is named HelloX.java where X is the number of the file
# Each file contains a class with a greetNum method that prints "Hello" + the number of the file
[genrule(
    name = "Hello" + str(x),
    outs = ["Hello" + str(x) + ".java"],
    cmd_bash = "echo 'package com.engflow.binaryinput;" + "\n" +
    "public class Hello" + str(x) +
    " { public static void greetNum() { System.out.println(\"Hello " + str(x) + "\"); } }' > $@",
) for x in range(1,NUM_FILES+1)]

#Generates a java library that contains all the generated java files
[java_library(
    name = "genbinary" + str(x),
    srcs = [":Hello" + str(x) + ".java" for x in range(1,NUM_FILES+1)],
    visibility = ["//visibility:public"],
) for x in range(1,NUM_FILES+1)]

#Main class
java_binary(
    name = "main",
    srcs = ["Main.java"],
    main_class = "com.engflow.binaryinput.Main",
    deps = [
        ":genbinary" + str(x) for x in range(1,NUM_FILES+1)
    ],
    args = [str(NUM_FILES)],
)