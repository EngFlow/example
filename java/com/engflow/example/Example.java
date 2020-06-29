package com.engflow.example;

public class Example {
  public static String fizzbuzz(int i) {
    if (i % 3 == 0) {
      if (i % 5 == 0) {
        return "FizzBuzz";
      }
      return "Fizz";
    } else if (i % 5 == 0) {
      return "Buzz";
    } else {
      return Integer.toString(i);
    }
  }
}
