# EngFlow public examples

This repository contains examples in various languages that demonstrate how to
build and test software with the EngFlow Remote Execution service.

## Prerequisites

- In order to build and test `//python`, you need to install the dependencies listed in `python/requirements.txt`. To do so, execute `bazel run //python:requirements.update` before testing.
- In order to run `//swift` test you need `clang` compiler. Make sure the binary is in your `PATH`. 

## Local execution
### Building locally

- Build each example with  

  `bazel build //${DIRECTORY}/...`  

  for `cpp`,  `csharp`, `docker`, `genrules`, `go`, `java`, `kotlin`, `perl`, `python`, `scala` and `typescript` or build them all with  
  
  `bazel build //...`
- Build `swift` example with  
  
  `bazel build //swift:test --config=clang`.

### Testing locally

- Test each example with

  `bazel test //${DIRECTORY}/...`  

  for `java`, `scala` and `typescript`.

- Test `swift` example with

  `bazel test //swift:test --config=clang`

- Test `python` example with

  `bazel test //python/...`

## Remote execution

Make sure to include `--remote_executor` and `--bes_backend`, in the `remote` configuration of your `.bazelrc.user` file , as well as access credentials if needed. For instance,

```bzl
build:remote --remote_executor=grpcs://${CLUSTER_ENDPOINT}/
build:remote --bes_backend=grpcs://${CLUSTER_ENDPOINT}/
build:remote --bes_results_url=https://${CLUSTER_ENDPOINT}/invocation/
build:remote --nogoogle_default_credentials
build:remote --bes_lifecycle_events
build:remote --tls_client_certificate=/path/to/credentials/cert.crt
build:remote --tls_client_key=/path/to/credentials/cert.key
```
### Building on remote


- Build each example with  

  `bazel build //${DIRECTORY}/... --config=remote --enable_platform_specific_config` 
  
  for `cpp`,  `csharp`, `docker`, `genrules`, `go`, `java`, `kotlin`, `perl`, `python`, `scala` or `typescript` or build them all with  
  
  `bazel build //... --config=remote  --enable_platform_specific_config`.
- `swift` example does not build remotely yet.

### Testing on remote

- Test each example with

  `bazel test //${DIRECTORY}/... --config=remote`  

  for `java`, `scala` and `typescript`.

- Test `python` example with

  `bazel test //python/... --config=remote`


## `engflowapis` execution

A detailed example of `EngFlow` APIs consumption is presented in [java/com/engflow/notificationqueue][1].

[1]: java/com/engflow/notificationqueue/README.md