package com.engflow.cycleexample.class_a;

import com.engflow.cycleexample.class_b.ClassB;
import com.engflow.cycleexample.class_c.ClassC;
import org.junit.Test;
import static org.junit.Assert.assertTrue;

public class ClassATest {
    private static class TestClassB extends ClassB {
        boolean methodBCalled = false;

        public TestClassB(ClassC classC) {
            super(classC);
        }

        @Override
        public void methodB(String input) {
            methodBCalled = true;
        }
    }

    @Test
    public void testMethodA() {
        // Create a ClassC instance with a null ClassA object
        ClassC classC = new ClassC(null);

        // Create a TestClassB instance with the ClassC object
        TestClassB testClassB = new TestClassB(classC);

        // Create a new ClassA instance with the TestClassB object
        ClassA classA = new ClassA(testClassB);

        // Properly initialize classC with classA
        classC.setClassA(classA);

        // Call methodA on classA with a sample input
        classA.methodA("sample input");

        // Verify that methodB on the TestClassB was called
        assertTrue(testClassB.methodBCalled);
    }
}