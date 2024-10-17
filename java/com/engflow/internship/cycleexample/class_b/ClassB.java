package com.engflow.internship.cycleexample.class_b;

import com.engflow.internship.cycleexample.class_c.ClassC;
import com.engflow.internship.cycleexample.interface_b.InterfaceB;

public class ClassB implements InterfaceB {
    private ClassC classC;

    public ClassB(ClassC classC) {
        this.classC = classC;
    }

    @Override
    public void methodB(String input) {
        // If the input is null or empty, return immediately
        if (input == null || input.isEmpty()) {
            return;
        }

        //Find the index of the first space character in the input string.
        int spaceIndex = input.indexOf(' ');
        //Extract the word from the beginning of the input string up to the space character.
        String word = (spaceIndex == -1) ? input : input.substring(0, spaceIndex);
        //Extract the remaining part of the input string after the space character.
        String remaining = (spaceIndex == -1) ? "" : input.substring(spaceIndex + 1);

        //Print the word extracted from the input string.
        System.out.println("ClassB: " + word);
        classC.methodA(remaining);
    }
}