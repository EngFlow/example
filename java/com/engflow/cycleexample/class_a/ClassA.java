package com.engflow.cycleexample.class_a;

import com.engflow.cycleexample.class_b.ClassB;
import com.engflow.cycleexample.interface_a.InterfaceA;

public class ClassA implements InterfaceA {
    private ClassB classB;

    public ClassA(ClassB classB) {
        this.classB = classB;
    }

    @Override
    public void methodA(String input) {
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
        System.out.println("ClassA: " + word);
        classB.methodB(remaining);
    }
}