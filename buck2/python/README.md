# EngFlow RE + Buck2 python example

This example demonstrates use of EngFlow RE for a simple python project built with [Buck2](https://github.com/facebook/buck2) using the prelude.

It is based on three existing samples in the Buck2 upstream repo and the EngFlow samples repo:

* Simple python project with prelude - https://github.com/facebook/buck2/tree/main/examples/with_prelude/python
* Buck2 remote execution integration with EngFlow - https://github.com/facebook/buck2/tree/main/examples/remote_execution/engflow
* EngFlow python example - https://github.com/EngFlow/example/tree/main/python

### Example structure

In the `platforms` cell we specify:
* The platform used for remote execution in this project `root//platforms:remote_platform`, which includes the definition of the Docker image used for remote execution, and that defines constraints for targets to run in the remote execution environment. This platform provides an `ExecutionPlatformRegistrationInfo`.
* The action keys `root//platforms:remote_execution_action_keys`, which provides a default `BuildModeInfo` that is needed for RE of tests to function properly.

In the `toolchains` cell we specify:

* The remote python toolchain `root//toolchains:remote_python_toolchain` that is compatible with the remote execution environment (uses by default `python3`).
* The remote test execution toolchain, `root//toolchains:remote_test_execution_toolchain`. This toolchain defines platform options in the form of `capabilities`. Critically these include the `container-image`. This toolchain is identical to the one in the `buck2/cpp` sample in this repo.

The `main` cell and `library` cell:

* Contains an copied version of https://github.com/facebook/buck2/tree/main/examples/with_prelude/python that works with Buck2 and RE as configured in this sample project.

To test these cells with RE run (after setting up `.buckconfig` as indicated below):

```
buck2 build //main:check_main
```

The `hello` cell:

* Contains a modified version of the python sample in https://github.com/EngFlow/example/tree/main/python that works with Buck2 and RE as configured  in this sample project.

To test this cell with RE run (after setting up `.buckconfig` as indicated below):

```
buck2 test //hello:hello_unittest_test
```

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
