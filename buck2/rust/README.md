# EngFlow RE + Buck2 Rust example

This example demonstrates use of EngFlow RE for a simple Rust project built with [Buck2](https://github.com/facebook/buck2) using the prelude.

It is based on two existing samples in the Buck2 upstream repo:

* Simple rust project with prelude - https://github.com/facebook/buck2/tree/main/examples/with_prelude/rust
* Buck2 remote execution integration with EngFlow - https://github.com/facebook/buck2/tree/main/examples/remote_execution/engflow

### Example structure

In the `platforms` cell we specify:
In the `platforms` cell we specify:
* The platform used for remote execution in this project `root//platforms:remote_platform`, which includes the definition of the Docker image used for remote execution, and that defines constraints for targets to run in the remote execution environment. This platform provides an `ExecutionPlatformRegistrationInfo` a `ConfigurationInfo` and a `PlatformInfo` to be able to be used in the `.buckconfig`.
* The action keys `root//platforms:remote_execution_action_keys`, which provides a default `BuildModeInfo` that is needed for RE of tests to function properly.
* The platform `image` configured in `platforms/defs.bzl`, notably, uses a different image than other Buck2 samples in this repo. Specifically, it uses a public AWS image that has `rust` preinstalled. This is because Buck2 rust rules do not include a hermetic rust toolchain. We use a bookworm image with rust pre-installed. Image details can be found in https://gallery.ecr.aws/docker/library/rust. The Dockerfile can be found in https://github.com/rust-lang/docker-rust/blob/700c4f146427808cfb1e07a646e4afabbe99da4f/stable/bullseye/Dockerfile. If a different version of `rust` or other tools is needed you should create your own image and publish it to a repo that is accessible from the cluster.

In the `toolchains` cell we specify:

* The remote rust toolchain `root//toolchains:remote_rust_toolchain` which is compatible with the remote execution environment. This toolchain is configured with the `rustc_target_triple` to match the remote execution environment, and the `compiler`, `clippy_driver` and `rustdoc` attrs are set to point to the location of the `rustc` binary in the image used for remote execution.
* The c++ toolchain `root//toolchains:cxx_tools_info_toolchain` that is compatible with the remote execution environment.
* The clang tools, `root//toolchains:path_clang_tools`, which is used by the c++ toolchain, and specifies the tools installed in the Docker image.
* The remote test execution toolchain, `root//toolchains:remote_test_execution_toolchain`. This toolchain defines platform options in the form of `capabilities`. Critically these include the `container-image`. This toolchain is identical to the one in the `buck2/cpp` sample in this repo.

The `src`, `bin` and `test` cells:

* Contain a copied version of https://github.com/facebook/buck2/tree/main/examples/with_prelude/rust that works with Buck2 and RE as configured in this sample project.

* Key changes for remote execution in the top level `BUCK` file include setting environment variables to select the pre-installed rust toolchain in the container and set a custom value for `HOME`. This custom value is needed as `rustp` attempts to create a directory in the `HOME` location and we prefer this happen inside the `buck-out/` directory to guarantee actions do not modify any content outside of their scratch directory.

To test the project with RE run (after setting up `.buckconfig` as indicated below):

```
buck2 test --remote-only //:test
```

You can also build the `main` for this sample by running:

```
buck2 build --remote-only //:main
```

Note the use of `--remote-only` to indicate remote execution should be used for the build / test command.

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
