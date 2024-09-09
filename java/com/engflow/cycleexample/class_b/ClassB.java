package com.engflow.cycleexample.class_b;

import com.engflow.cycleexample.class_c.ClassC;
import com.engflow.cycleexample.interface_b.InterfaceB;

public class ClassB implements InterfaceB {
    private ClassC classC;

    public ClassB(ClassC classC) {
        this.classC = classC;
    }

    @Override
    public void methodB() {
        System.out.println("ClassB.methodB()");
        classC.methodA();
    }
}
