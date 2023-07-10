"""An example Python test using Python's built-in unittest module."""

import unittest

from python import hello


class HelloTest(unittest.TestCase):
    def test_hello(self):
        self.assertEqual("Hello", hello.hello())

    def test_goodbye(self):
        self.assertEqual("Goodbye", hello.goodbye())


if __name__ == "__main__":
    unittest.main()
