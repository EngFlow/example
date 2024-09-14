package com.engflow.internship.cycleexample.class_c;

import com.engflow.internship.cycleexample.interface_a.InterfaceA;

public class ClassC implements InterfaceA {
    private InterfaceA classA;

    public ClassC(InterfaceA classA) {
        this.classA = classA;
    }

    @Override
    public void methodA() {
        System.out.println("ClassC.methodA()");
        if (classA != null) {
            classA.methodA();
        } else {
            System.out.println("classA is null");
        }
    }

    public void setClassA(InterfaceA classA) {
        this.classA = classA;
    }

    public void methodC() {
        System.out.println("ClassC.methodC()");
    }
}