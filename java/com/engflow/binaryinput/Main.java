package com.engflow.binaryinput;

import java.lang.reflect.InvocationTargetException;

public class Main {
    public static void main(String[] args) {
        try {
            // args[0] is the number of files to read
            int numFiles = Integer.parseInt(args[0]);

            // Load and run the greetNum method from each class
            for(int i = 1; i <= numFiles; i++){
                Class<?> clazz = Class.forName("com.engflow.internship.binaryinput.Hello" + i);
                clazz.getMethod("greetNum").invoke(null);
            }

        } catch (ClassNotFoundException | InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
            throw new RuntimeException(e);
        }
    }
}
