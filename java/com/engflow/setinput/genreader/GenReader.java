package com.engflow.setinput.genreader;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.BufferedReader;

public class GenReader {

    /**
     * Reads the content of the specified file and prints it to the console.
     * @param inputPath
     */
    public void readFiles(String inputPath) {
        File file = new File(inputPath);

        // Check if the file exists and is a file
        if (!file.exists() || !file.isFile()) {
            System.out.println("Invalid file path: " + inputPath + "\n Absolute path: " + file.getAbsolutePath()+
            "\n File: " + file);
            return;
        }

        // Read the content of the file and print it to the console
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
