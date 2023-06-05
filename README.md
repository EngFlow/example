# EngFlow public examples

This repository contains examples in various languages that demonstrate how to
build and test software with the EngFlow Remote Execution service.

## Building locally

- Build each example with  

  `bazel build //${DIRECTORY}/...`  

  for `cpp`,  `csharp`, `docker`, `genrules`, `go`, `java`, `kotlin`, `perl`, `python`, `scala` and `typescript` or build them all with  
  
  `bazel build //...`
- Build `swift` example with  
  
  `bazel build //swift/... --config=clang` 
  
  make sure `clang` is in your `PATH`.

## Building on remote cluster


- Build each example with  

  `bazel build //${DIRECTORY}/... --config=remote` 
  
  for `cpp`,  `csharp`, `docker`, `genrules`, `go`, `java`, `kotlin`, `perl`, `python`, `scala` or `typescript` or build them all with  
  
  `bazel build //... --config=remote`.
- `swift` example does not build remotely yet.

Make sure to include `--remote_executor` and `--bes_backend`, in your remote configuration, as well as access credentials if needed. For instance,


```bzl
build:remote --remote_executor=grpcs://${CLUSTER_ENDPOINT}/
build:remote --bes_backend=grpcs://${CLUSTER_ENDPOINT}/
build:remote --bes_results_url=https://${CLUSTER_ENDPOINT}/invocation/
build:remote --nogoogle_default_credentials
build:remote --bes_lifecycle_events
build:remote --tls_client_certificate=/path/to/credentials/cert.crt
build:remote --tls_client_key=/path/to/credentials/cert.key
```


## `engflowapis` execution

A detailed example of `EngFlow` APIs consumption is presented in [java/com/engflow/notificationqueue/][1].

[1]: java/com/engflow/notificationqueue/README.md