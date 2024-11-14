"""An example Python test using Python's built-in unittest module."""

import unittest

from hellolib.hello import hello
from hellolib.hello import goodbye


class HelloTest(unittest.TestCase):
    def test_hello(self):
        self.assertEqual("Hello", hello())

    def test_goodbye(self):
        self.assertEqual("Goodbye", goodbye())


if __name__ == "__main__":
    unittest.main()
