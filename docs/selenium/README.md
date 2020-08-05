# Building Selenium w/ EngFlow Remote Execution

```
$ git clone https://github.com/SeleniumHQ/selenium.git selenium
$ cd selenium
$ curl https://raw.githubusercontent.com/EngFlow/example/master/engflow-ca.crt > engflow-ca.crt
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/selenium/bazelrc >> .bazelrc.local
$ echo "build:engflow --tls_client_certificate=name@example.com.crt" >> .bazelrc.local
$ echo "build:engflow --tls_client_key=name@example.com.crt" >> .bazelrc.local
$ bazel build --config=engflow //java/... //py/... //deploys/...
```
