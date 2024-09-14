package com.engflow.internship.cycleexample.class_a;

import com.engflow.internship.cycleexample.class_b.ClassB;
import com.engflow.internship.cycleexample.class_c.ClassC;
import org.junit.Test;
import static org.junit.Assert.assertTrue;

public class ClassATest {
    private static class TestClassB extends ClassB {
        boolean methodBCalled = false;

        public TestClassB(ClassC classC) {
            super(classC);
        }

        @Override
        public void methodB() {
            methodBCalled = true;
        }
    }

    @Test
    public void testMethodA() {
        // Create an instance of ClassA
        ClassA classA = new ClassA(null);

        // Create a ClassC instance with the ClassA object
        ClassC classC = new ClassC(classA);

        // Create a TestClassB instance with the ClassC object
        TestClassB testClassB = new TestClassB(classC);

        // Create a new ClassA instance with the TestClassB object
        classA = new ClassA(testClassB);

        // Call methodA on classA
        classA.methodA();

        // Verify that methodB on the TestClassB was called
        assertTrue(testClassB.methodBCalled);
    }
}