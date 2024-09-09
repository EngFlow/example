package com.engflow.cycleexample.main;

import com.engflow.cycleexample.class_a.ClassA;
import com.engflow.cycleexample.class_b.ClassB;
import com.engflow.cycleexample.class_c.ClassC;

public class Main {
    public static void main(String[] args) {
        ClassC classC = new ClassC(null);
        ClassB classB = new ClassB(classC);
        ClassA classA = new ClassA(classB);

        // Properly initialize classC with classA
        classC.setClassA(classA);

        classA.methodA();
    }
}