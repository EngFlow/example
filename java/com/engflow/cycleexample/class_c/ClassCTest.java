package com.engflow.cycleexample.class_c;

import com.engflow.cycleexample.class_a.ClassA;
import org.junit.Test;
import static org.junit.Assert.assertTrue;

public class ClassCTest {
    private static class TestClassA extends ClassA {
        boolean methodACalled = false;

        public TestClassA() {
            super(null);
        }

        @Override
        public void methodA() {
            methodACalled = true;
        }
    }

    @Test
    public void testMethodA() {
        // Create a TestClassA instance
        TestClassA testClassA = new TestClassA();

        // Create an instance of ClassC with the TestClassA object
        ClassC classC = new ClassC(testClassA);

        // Call methodA on classC
        classC.methodA();

        // Verify that methodA on the TestClassA was called
        assertTrue(testClassA.methodACalled);
    }
}