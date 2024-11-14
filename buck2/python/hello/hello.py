"""Example Python module."""

import sys


def hello():
    return "Hello"


def goodbye():
    print("goodbye called", file=sys.stderr)
    return "Goodbye"
