package com.engflow.cycleexample.class_a;

import com.engflow.cycleexample.class_b.ClassB;
import com.engflow.cycleexample.interface_a.InterfaceA;

public class ClassA implements InterfaceA {
    private static final int MAX_CALLS = 10;
    private int callCount = 0;
    private ClassB classB;

    public ClassA(ClassB classB) {
        this.classB = classB;
    }

    @Override
    public void methodA() {
        if (callCount >= MAX_CALLS) {
            System.out.println("ClassA.methodA() reached max calls");
            return;
        }
        System.out.println("ClassA.methodA()");
        callCount++;
        classB.methodB();
    }
}
