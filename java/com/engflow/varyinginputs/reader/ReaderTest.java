package com.engflow.varyinginputs.reader;

import org.junit.Test;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import static org.junit.Assert.assertTrue;

public class ReaderTest {

    @Test
    public void testReadFilesPrintsFileContents() throws IOException {
        Reader reader = new Reader();
        String inputPath = "test_input";
        String fileName = "testFile.txt";
        String fileContent = "Hello, World!";

        // Set up test files
        File directory = new File(inputPath);
        directory.mkdirs();
        File testFile = new File(inputPath + "/" + fileName);
        try (FileWriter writer = new FileWriter(testFile)) {
            writer.write(fileContent);
        }

        // Capture the output
        java.io.ByteArrayOutputStream outContent = new java.io.ByteArrayOutputStream();
        System.setOut(new java.io.PrintStream(outContent));

        // Run the method
        reader.readFiles(inputPath);

        // Verify the output
        String expectedOutput = "Reading file: " + fileName + "\n" + fileContent + "\n";
        assertTrue(outContent.toString().contains(expectedOutput));

        // Clean up after test
        testFile.delete();
        directory.delete();
    }

    @Test
    public void testReadFilesHandlesEmptyDirectory() {
        Reader reader = new Reader();
        String inputPath = "empty_test_input";

        // Set up empty directory
        File directory = new File(inputPath);
        directory.mkdirs();

        // Capture the output
        java.io.ByteArrayOutputStream outContent = new java.io.ByteArrayOutputStream();
        System.setOut(new java.io.PrintStream(outContent));

        // Run the method
        reader.readFiles(inputPath);

        // Verify the output
        String expectedOutput = "No files found in the directory: " + inputPath + "\n";
        assertTrue(outContent.toString().contains(expectedOutput));

        // Clean up after test
        directory.delete();
    }
}
