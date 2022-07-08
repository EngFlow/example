# Preparing your code base for Remote Execution

This is an example project that simulates a remote execution environment.

Usage:

```sh
bazel build --config=docker-sandbox //:all
```

# How does it work

Bazel can simulate building in a remote execution environment. It doesn't need an actual cluster for
this: it can run actions in a local Docker container.

This runs actions with the same constraints as a remote execution service does. You can use this
execution method to find targets that aren't compatible with remote execution, and prepare your code
base before you start using real remote execution.

