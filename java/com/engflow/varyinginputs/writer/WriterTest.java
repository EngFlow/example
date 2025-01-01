package com.engflow.varyinginputs.writer;

import org.junit.Test;
import java.io.File;
import java.io.IOException;
import static org.junit.Assert.assertEquals;

public class WriterTest {

    @Test
    public void testWriteFilesCreatesCorrectNumberOfFiles() throws IOException {
        Writer writer = new Writer();
        String outputPath = "test_output";
        int numberOfFiles = 5;

        // Clean up before test
        File directory = new File(outputPath);
        if (directory.exists()) {
            for (File file : directory.listFiles()) {
                file.delete();
            }
            directory.delete();
        }

        // Run the method
        writer.writeFiles(numberOfFiles, outputPath);

        // Verify the number of files created
        File[] files = new File(outputPath).listFiles();
        assertEquals(numberOfFiles, files.length);

        // Clean up after test
        for (File file : files) {
            file.delete();
        }
        new File(outputPath).delete();
    }

    @Test
    public void testWriteFilesDeletesExcessFiles() throws IOException {
        Writer writer = new Writer();
        String outputPath = "test_output";
        int initialNumberOfFiles = 10;
        int finalNumberOfFiles = 5;

        // Create initial files
        File directory = new File(outputPath);
        directory.mkdirs();
        for (int i = 0; i < initialNumberOfFiles; i++) {
            new File(outputPath + "/file" + i + ".txt").createNewFile();
        }

        // Run the method
        writer.writeFiles(finalNumberOfFiles, outputPath);

        // Verify the number of files after deletion
        File[] files = new File(outputPath).listFiles();
        assertEquals(finalNumberOfFiles, files.length);

        // Clean up after test
        for (File file : files) {
            file.delete();
        }
        new File(outputPath).delete();
    }
}