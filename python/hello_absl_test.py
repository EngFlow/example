"""An example Python test using Abseil Python.

See https://abseil.io/docs/python/guides/testing
"""

from absl.testing import absltest

from python import hello


class HelloTest(absltest.TestCase):
    def test_hello(self):
        self.assertEqual("Hello", hello.hello())

    def test_goodbye(self):
        self.assertEqual("Goodbye", hello.goodbye())


if __name__ == "__main__":
    absltest.main()
