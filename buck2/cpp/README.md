# EngFlow RE + Buck2 cpp example

This example demonstrates use of EngFlow RE for a simple C++ project built with Buck2 using the prelude.

It is based on two existing samples in the Buck2 upstream repo:

* Simple cpp Hello World project - https://github.com/facebook/buck2/tree/804d62242214455d51787f7c8c96a1e12c75ec32/examples/hello_world
* Buck2 remote execution integration with EngFlow - https://github.com/facebook/buck2/tree/804d62242214455d51787f7c8c96a1e12c75ec32/examples/remote_execution/engflow

### Example structure

In the `platforms` cell we specify:
* The platform used for remote execution in this project `root//platforms:remote_platform`, which includes the definition of the Docker image used for remote execution.
* The `execution_platform`, `root//platforms:remote` that defines constraints for targets to run in the remote execution environment. 

In the `toolchains` cell we specify:

* The c++ toolchain `root//toolchains:cxx_tools_info_toolchain` that is compatible with the remote execution environment.
* The clang tools, `root//toolchains:path_clang_tools, which is used by the c++ toolchain, and specifies the tools installed in the Docker image.

The main `BUCK` file defines:

* A `cxx_binary` binary target that has the `exec_compatible_with` attr pointing to the `root//platforms:remote_platform` target and the `default_target_platform` attr pointing to the `root//platforms:remote` target.

### Relevant configs in `.buckconfig`

The EngFlow endpoint and certificate should be configured as the
following:

```ini
[buck2_re_client]
engine_address       = <CLUSTER_NAME>.cluster.engflow.com
action_cache_address = <CLUSTER_NAME>.cluster.engflow.com
cas_address          = <CLUSTER_NAME>.cluster.engflow.com
tls_client_cert      = x-engflow-auth-method:jwt-v0,x-engflow-auth-token:LONG_JWT_STRING
 ```

 To obtain the value of `LONG_JWT_STRING`, log into https://<CLUSTER_NAME>.cluster.engflow.com/gettingstarted and use the value of `x-engflow-auth-token` in section `Method 2: JWT`.

### Usage instructions

Clone the repository and replace the relevant configs in `.buckconfig`.

Build and run the example:

```
buck2 build //:main
buck2 run -v 4 //:main
```
