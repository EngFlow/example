package com.engflow.internship.setinput.main;

import com.engflow.internship.setinput.genreader.GenReader;

public class Main {

    public static void main(String[] args) {
        GenReader reader = new GenReader();

        String filePath = "//java/com/engflow/internship/setinput/genfile:genfile";

        reader.readFiles(filePath);
    }
}