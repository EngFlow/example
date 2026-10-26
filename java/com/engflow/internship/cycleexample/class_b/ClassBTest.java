package com.engflow.internship.cycleexample.class_b;

import com.engflow.internship.cycleexample.class_c.ClassC;
import org.junit.Test;
import static org.junit.Assert.assertTrue;

public class ClassBTest {
    private static class TestClassC extends ClassC {
        boolean methodACalled = false;

        public TestClassC() {
            super(null);
        }

        @Override
        public void methodA(String input) {
            methodACalled = true;
        }
    }

    @Test
    public void testMethodB() {
        // Create a TestClassC instance
        TestClassC testClassC = new TestClassC();

        // Create an instance of ClassB with the TestClassC object
        ClassB classB = new ClassB(testClassC);

        // Call methodB on classB
        classB.methodB("Sample input");

        // Verify that methodA on the TestClassC was called
        assertTrue(testClassC.methodACalled);
    }
}