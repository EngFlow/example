import unittest

# Bazel seems to be setting the PYTHON_PATH wrong, resulting in a
# parent "python" module. This might be a regression.
from python.example import fizzbuzz


class ExampleTest(unittest.TestCase):
    def test_fizzbuzz(self):
        self.assertEqual(fizzbuzz(1), "1")
        self.assertEqual(fizzbuzz(2), "2")
        self.assertEqual(fizzbuzz(3), "Fizz")
        self.assertEqual(fizzbuzz(4), "4")
        self.assertEqual(fizzbuzz(5), "Buzz")
        self.assertEqual(fizzbuzz(15), "FizzBuzz")


if __name__ == "__main__":
    unittest.main()
