package com.engflow.internship.cycleexample.main;

import com.engflow.internship.cycleexample.class_a.ClassA;
import com.engflow.internship.cycleexample.class_b.ClassB;
import com.engflow.internship.cycleexample.class_c.ClassC;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        //Input file path
        String fileName = "java/com/engflow/internship/cycleexample/input/input.txt";
        StringBuilder content = new StringBuilder();

        //Read the input file and store the content in a StringBuilder
        try (BufferedReader br = new BufferedReader(new FileReader(fileName))) {
            String line;
            while ((line = br.readLine()) != null) {
                content.append(line).append(" ");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        String input = content.toString().trim();

        // Create instances of ClassA, ClassB, and ClassC
        ClassC classC = new ClassC(null);
        ClassB classB = new ClassB(classC);
        ClassA classA = new ClassA(classB);

        // Properly initialize classC with classA
        classC.setClassA(classA);

        classA.methodA(input);
    }
}