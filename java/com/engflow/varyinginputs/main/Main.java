package com.engflow.varyinginputs.main;

import com.engflow.varyinginputs.reader.Reader;
import com.engflow.varyinginputs.writer.Writer;

public class Main {

    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Please provide the number of files as an argument.");
            return;
        }

        int numberOfFiles;
        try {
            numberOfFiles = Integer.parseInt(args[0]);
        } catch (NumberFormatException e) {
            System.out.println("Invalid number format: " + args[0]);
            return;
        }

        Writer writer = new Writer();
        Reader reader = new Reader();

        String filePath = "com/engflow/varyinginputs/input";

        writer.writeFiles(numberOfFiles, filePath);
        reader.readFiles(filePath);
    }
}