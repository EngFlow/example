package com.engflow.internship.varyinginputs.writer;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Random;
import java.util.UUID;

public class Writer {

    /**
     * Write the specified number of files to the output path.
     * @param numberOfFiles
     * @param outputPath
     */
    public void writeFiles(int numberOfFiles, String outputPath) {
        File directory = new File(outputPath);

        if (!directory.exists()) {
            directory.mkdirs();
        }

        // list all files in the directory and count them
        File[] existingFiles = directory.listFiles();
        int existingFilesCount = existingFiles != null ? existingFiles.length : 0;

        Random random = new Random();

        // create new files if the number of existing files is less than the required number
        if (existingFilesCount < numberOfFiles) {
            for (int i = existingFilesCount; i < numberOfFiles; i++) {
                // create a new file with a unique name to avoid conflicts
                String fileName = outputPath + "/file" + UUID.randomUUID() + ".txt";
                File file = new File(fileName);

                try {
                    // write 100 random characters to the file
                    file.createNewFile();
                    FileWriter writer = new FileWriter(file);
                    for (int j = 0; j < 100; j++) {
                        char randomChar = (char) (random.nextInt(26) + 'a');
                        writer.write(randomChar);
                    }
                    writer.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        // delete files if the number of existing files is greater than the required number
        else if (existingFilesCount > numberOfFiles) {
            while (existingFilesCount > numberOfFiles) {
                int fileIndex = random.nextInt(existingFilesCount);
                File fileToDelete = existingFiles[fileIndex];
                if (fileToDelete.delete()) {
                    existingFilesCount--;
                }
            }
        }
    }
}