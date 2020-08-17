# Building TensorFlow w/ EngFlow Remote Execution

This directory contains almost everything needed to get started building the open-source
[TensorFlow](https://github.com/tensorflow/tensorflow) project on an EngFlow Remote Execution
cluster. In addition to the files and documentation here, you also need to run your own cluster or
obtain access to an existing cluster.

Below, we use `name@example.com.crt` and `name@example.com.key` as the client cert and key for
TLS client authentication. Other methods may apply depending on the cluster configuration.

```
$ git clone https://github.com/tensorflow/tensorflow.git tensorflow
$ cd tensorflow
$ curl https://raw.githubusercontent.com/EngFlow/example/master/engflow-ca.crt > engflow-ca.crt
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/tensorflow/0001-Update-.bazelrc-settings-for-EngFlow-RE.patch > 0001-Update-.bazelrc-settings-for-EngFlow-RE.patch
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/tensorflow/0002-Use-absolute-paths-for-which-and-find.patch > 0002-Use-absolute-paths-for-which-and-find.patch
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/tensorflow/0003-Disable-Pool-platform-option.patch > 0003-Disable-Pool-platform-option.patch
$ git am ../*.patch
$ echo "build:engflow --tls_client_certificate=name@example.com.crt" >> .bazelrc.user
$ echo "build:engflow --tls_client_key=name@example.com.crt" >> .bazelrc.user
$ bazel build --config=rbe_cpu_linux --config=rbe_linux_py3 -c opt -k --jobs=75 //tensorflow/tools/pip_package:build_pip_package
```

# Known Issues

1. EngFlow RE returns a symlink for one .so link action which Bazel does not support when running
   with `--experimental_remote_download_outputs=minimal`, which is set in the TensorFlow
   `.bazelrc`.

