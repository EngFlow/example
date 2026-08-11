package com.engflow.internship.setinput.main;

import com.engflow.internship.setinput.genreader.GenReader;

import java.nio.file.Paths;
import java.nio.file.Files;
import java.io.IOException;

public class Main {

    public static void main(String[] args) {
        String genfilePath = "java/com/engflow/internship/setinput/genfile"; // Path relative to bazel-bin
        String workspacePath = System.getenv("BUILD_WORKING_DIRECTORY");
        //System.out.println("Workspace path: " + workspacePath);

        if (workspacePath == null) {
            System.out.println("Workspace path could not be determined.");
            return;
        }

        String bazelBinPath = Paths.get(workspacePath, "bazel-bin").toString();
        //System.out.println("Bazel-bin path: " + bazelBinPath);
        String fullPath = Paths.get(bazelBinPath, genfilePath).toString();

        GenReader reader = new GenReader();
        try {
            Files.list(Paths.get(fullPath))
                    .filter(Files::isRegularFile)
                    .forEach(file -> reader.readFiles(file.toString()));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}