# EngFlow RE + Buck2 cpp example

This example demonstrates use of EngFlow RE for a simple C++ project built with [Buck2](https://github.com/facebook/buck2) using the prelude.

It is based on two existing samples in the Buck2 upstream repo:

* Simple cpp Hello World project - https://github.com/facebook/buck2/tree/804d62242214455d51787f7c8c96a1e12c75ec32/examples/hello_world
* Buck2 remote execution integration with EngFlow - https://github.com/facebook/buck2/tree/804d62242214455d51787f7c8c96a1e12c75ec32/examples/remote_execution/engflow

### Example structure

In the `platforms` cell we specify:
* The platform used for remote execution in this project `root//platforms:remote_platform`, which includes the definition of the Docker image used for remote execution, and that defines constraints for targets to run in the remote execution environment. This platform provides an `ExecutionPlatformRegistrationInfo` a `ConfigurationInfo` and a `PlatformInfo` to be able to be used in the `.buckconfig`, and in the `exec_compatible_with` and `default_target_platform` of `cxx_*` rules.
* The `root//platforms:remote_execution_action_keys` target that provides a `BuildModeInfo` which is necessary for the prelude to correctly configure remote execution of tests. It defines two attributes that can be used as cache silo keys.

In the `toolchains` cell we specify:

* The c++ toolchain `root//toolchains:cxx_tools_info_toolchain` that is compatible with the remote execution environment.
* The clang tools, `root//toolchains:path_clang_tools`, which is used by the c++ toolchain, and specifies the tools installed in the Docker image.
* The remote test execution toolchain, `root//toolchains:remote_test_execution_toolchain`. This toolchain defines platform options in the form of `capabilities`. Critically these include the `container-image`.

The main `BUCK` file defines:

* A `cxx_binary` target that has the `exec_compatible_with` as well as the `default_target_platform` attrs pointing to the `root//platforms:remote_platform`.
* A `cxx_library`target that has the `exec_compatible_with` as well as the `default_target_platform` attrs pointing to the `root//platforms:remote_platform`.
* A `cxx_test` target that has the `exec_compatible_with` as well as the `default_target_platform` attrs pointing to the `root//platforms:remote_platform`. It also has a `remote_execution_action_key_providers` attr that points to the `root//platforms:remote_execution_action_keys` target.

### Relevant configs in `.buckconfig`

The EngFlow endpoint and certificate should be configured as the
following:

```ini
[buck2_re_client]
engine_address       = <CLUSTER_NAME>.cluster.engflow.com
action_cache_address = <CLUSTER_NAME>.cluster.engflow.com
cas_address          = <CLUSTER_NAME>.cluster.engflow.com
http_headers         = <AUTH_HTTP_HEADERS>
 ```

To obtain the value of `<AUTH_HTTP_HEADERS>`, log into https://<CLUSTER_NAME>.cluster.engflow.com/gettingstarted and obtain the value of `x-engflow-auth-token` in section `Method 2: JWT`, take note of this value. Then set `AUTH_HTTP_HEADERS` with the value `x-engflow-auth-method:jwt-v0,x-engflow-auth-token:<JWT_TOKEN_FROM_GETTINGSTARTED_PAGE>.

Note for CI runs, the auth method used is [Github Tokens](https://docs.engflow.com/re/config/authentication.html#github-tokens).

### Usage instructions

Clone the repository and replace the relevant configs in `.buckconfig`.

Build the example:

```
buck2 build //:cpp_lib
```

Test the example:

```
buck2 test //:cpp_test
```
