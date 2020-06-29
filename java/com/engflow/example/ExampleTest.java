package com.engflow.example;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class ExampleTest {
  @Test
  public void various() {
    assertEquals("1", Example.fizzbuzz(1));
    assertEquals("2", Example.fizzbuzz(2));
    assertEquals("Fizz", Example.fizzbuzz(3));
    assertEquals("4", Example.fizzbuzz(4));
    assertEquals("Buzz", Example.fizzbuzz(5));
    assertEquals("FizzBuzz", Example.fizzbuzz(15));
  }
}
