package com.engflow.example
import org.scalatest.FunSuite

class ScalaExampleTest extends FunSuite  {
    test ("engflow scala tests") {
        assert("1" == ScalaExample.fizzbuzz(1))
        assert("2" == ScalaExample.fizzbuzz(2))
        assert("Fizz" == ScalaExample.fizzbuzz(3))
        assert("4" == ScalaExample.fizzbuzz(4))
        assert("Buzz" == ScalaExample.fizzbuzz(5))
        assert("FizzBuzz" == ScalaExample.fizzbuzz(15))
    }
}
