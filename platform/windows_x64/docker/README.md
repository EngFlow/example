This directory contains a minimal Dockerfile you can use to build a container image to be used with remote execution.

See https://docs.engflow.com/re/client/create-container.html for a complete explanation on what tools should be installed in a container image, where the image should be stored, and how to configure Bazel to use your image.

To build this image, run `platform/windows_x64/docker/build.ps1` from the workspace root directory instead of running `docker build` directly. This builds `//infra/msvc_filter_showincludes` using Bazel. That tool is used by the MSVC toolchain to work around [bazelbuild/bazel#19733](https://github.com/bazelbuild/bazel/issues/19733).
