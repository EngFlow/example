package com.engflow.varyinginputs.reader;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.BufferedReader;

public class Reader {

    /**
     * Reads the content of all files in the specified directory and prints it to the console.
     * @param inputPath
     */
    public void readFiles(String inputPath) {
        File directory = new File(inputPath);

        // Check if the directory exists and is a directory
        if (!directory.exists() || !directory.isDirectory()) {
            System.out.println("Invalid directory path: " + inputPath);
            return;
        }

        // List all files in the directory and check if there are any
        File[] files = directory.listFiles();
        if (files == null || files.length == 0) {
            System.out.println("No files found in the directory: " + inputPath);
            return;
        }

        // Read the content of each file and print it to the console
        for (File file : files) {
            if (file.isFile()) {
                try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                    String line;
                    System.out.println("Reading file: " + file.getName());
                    while ((line = reader.readLine()) != null) {
                        System.out.println(line);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
