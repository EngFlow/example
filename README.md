# EngFlow public examples

This repository contains examples in various languages that demonstrate how to
build and test software with the EngFlow Remote Execution service.

## Prerequisites

- `//python`: Bazel needs to install the dependencies listed in
  `python/requirements.txt`. To make this repository work across platforms, we
  do not check in a lock file. Execute the following commands to generate
  the lock file before building and testing:

  ```sh
  # https://stackoverflow.com/a/73720550
  git update-index --skip-worktree python/requirements_lock.txt
  bazel run //python:requirements.update
  ```

- `//swift`: Requires the `clang` compiler. Make sure the binary is in your
  `PATH`.

  **`//swift` also does not yet build remotely on platforms other than macOS**,
  due to lack of support in [rules_swift][2].

  The [implementation of `swift_autoconfiguration` as of v1.18.0][3] does not
  yet use the [Bazel `toolchain` API][4]. Instead, it selects the platform based
  on the `os.name` Java system property, and on Linux, expects `swiftc` to exist
  on the system already:

  - [repository_ctx.os][5]
  - [repository_os.name][6]
  - [`_create_linux_toolchain()` checks for `swiftc`][7]

  Other language rule sets contain logic to download the appropriate language
  SDK on demand.

  The following issues track the eventual addition of `toolchain` support and
  automatic SDK downloads on Linux (both opened 2018-06-06):

  - [bazelbuild/rules_swift: Migrate to platforms/toolchains API #3][8]
  - [bazelbuild/rules_swift: Auto-download Linux toolchains when possible #4][9]

## Local execution

Make sure that you can build and run the tests in the language of your choice
locally before attempting remote execution.

### Building locally

- `cpp`,  `csharp`, `docker`, `genrules`, `go`, `java`, `kotlin`, `perl`,
  `python`, `scala`, and `typescript`:

  ```sh
  bazel build //${DIRECTORY}/...
  ```

  Build them all with:

  ```sh
  bazel build //...
  ```

- `swift`:

  ```sh
  # --config=clang isn't required on macOS
  bazel build --config=clang //swift:tests
  ```

### Testing locally

- `java`, `python`, `scala`, and `typescript`:

  ```sh
  bazel test //${DIRECTORY}/...
  ```

  Test them all with:

  ```sh
  bazel test //...
  ```

- `swift`:

  ```sh
  # --config=clang isn't required on macOS
  bazel test --config=clang //swift:tests
  ```

## Remote execution

Make sure to include `--remote_executor` and `--bes_backend`, in the `engflow`
configuration of your `.bazelrc.user` file, as well as access credentials if
needed. For instance:

```bzl
# Incorporate configurations from .bazelrc, which imports this file.
#
# - Depending on your cluster configuration, replace remote_linux_64 with
#   remote_macos_x64 or remote_windows_x64.
build:engflow --config=engflow_common
build:engflow --config=remote_linux_x64

# Configuration for your trial cluster
build:engflow --remote_executor=grpcs://${CLUSTER_ENDPOINT}/
build:engflow --bes_backend=grpcs://${CLUSTER_ENDPOINT}/
build:engflow --bes_results_url=https://${CLUSTER_ENDPOINT}/invocation/
build:engflow --nogoogle_default_credentials
build:engflow --bes_lifecycle_events

# Configuration for your mTLS certificates (if required)
build:engflow --tls_client_certificate=/path/to/credentials/cert.crt
build:engflow --tls_client_key=/path/to/credentials/cert.key

# This ensures _all_ build and test runs will be remote. Comment this out
# when building locally.
build --config=engflow
```

### Building on remote

- `cpp`,  `csharp`, `docker`, `genrules`, `go`, `java`, `kotlin`, `perl`,
  `python`, `scala`, or `typescript`:

  ```sh
  bazel build //${DIRECTORY}/...
  ```

  Build them all with:

  ```sh
  bazel build //...
  ```

- `swift`:

  ```sh
  bazel build //swift:tests
  ```

### Testing on remote

- `java`, `python`, `scala`, and `typescript`:

  ```sh
  bazel test //${DIRECTORY}/...
  ```

  Test them all with:

  ```sh
  bazel test //...
  ```

- `swift`:

  ```sh
  bazel test //swift:tests
  ```

## `engflowapis` execution

A detailed example of `EngFlow` APIs consumption is presented in
[java/com/engflow/notificationqueue][1].

[1]: java/com/engflow/notificationqueue/README.md
[2]: https://github.com/bazelbuild/rules_swift
[3]: https://github.com/bazelbuild/rules_swift/blob/1.18.0/swift/internal/swift_autoconfiguration.bzl#L428-L438
[4]: https://bazel.build/extending/toolchains
[5]: https://bazel.build/rules/lib/builtins/repository_ctx#os
[6]: https://bazel.build/rules/lib/builtins/repository_os.html#name
[7]: https://github.com/bazelbuild/rules_swift/blob/1.18.0/swift/internal/swift_autoconfiguration.bzl#L268-L269
[8]: https://github.com/bazelbuild/rules_swift/issues/3
[9]: https://github.com/bazelbuild/rules_swift/issues/4
