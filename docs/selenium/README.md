# Building Selenium w/ EngFlow Remote Execution

```
$ git clone 
$ cd selenium
$ curl https://raw.githubusercontent.com/EngFlow/example/master/engflow-ca.crt > engflow-ca.crt
$ curl https://raw.githubusercontent.com/EngFlow/example/master/docs/selenium/bazelrc > .bazelrc.local
$ bazel build --config=engflow //java/... //py/... //deploys/...
```
