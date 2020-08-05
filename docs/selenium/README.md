# Building Selenium w/ EngFlow Remote Execution

This directory contains almost everything needed to get started building the open-source
[Selenium](https://github.com/SeleniumHQ/selenium) project on an EngFlow Remote Execution cluster.
In addition to the files and documentation here, you also need to run your own cluster or obtain
access to an existing cluster.

Below, we use `name@example.com.crt` and `name@example.com.key` as the client cert and key for
TLS client authentication. Other methods may apply depending on the cluster configuration.

```
$ git clone https://github.com/SeleniumHQ/selenium.git selenium
$ cd selenium
$ curl https://raw.githubusercontent.com/EngFlow/example/master/engflow-ca.crt > engflow-ca.crt
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/selenium/bazelrc >> .bazelrc.local
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/selenium/WORKSPACE >> WORKSPACE
$ echo "build:engflow --tls_client_certificate=name@example.com.crt" >> .bazelrc.local
$ echo "build:engflow --tls_client_key=name@example.com.crt" >> .bazelrc.local
$ bazel build --config=engflow //java/... //py/... //deploys/...
```
