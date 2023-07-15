"""An example Python test using Pytest.

See https://docs.pytest.org/
"""

from python import hello


def test_hello():
    assert "Hello" == hello.hello()


def test_goodbye():
    assert "Goodbye" == hello.goodbye()
