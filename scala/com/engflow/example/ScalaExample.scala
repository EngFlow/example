package com.engflow.example;

object ScalaExample {
  def fizzbuzz(i: Int): String = {
    if (i % 3 == 0){
      if (i % 5 == 0){
        return "FizzBuzz";
      }
      return "Fizz";
    } else if (i % 5 == 0){
      return "Buzz";
    } else {
      return Integer.toString(i);
    }
  }
}
