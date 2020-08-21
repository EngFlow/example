# Building libcyaml w/ Goma & EngFlow Remote Execution

This directory contains everything needed to get started using the open source
Goma tool to talk to an EngFlow Remote Execution cluster.
In addition to the files and documentation here, you also need to run your own
cluster or obtain access to an existing cluster.

TODO: Figure out how to authenticate the Goma server to the cluster.
TODO: Figure out how to get better relative paths.

The first step is to run Goma server and point it at an EngFlow Remote Execution
cluster:
```
curl https://raw.githubusercontent.com/EngFlow/example/master/engflow-ca.crt > engflow-ca.crt
curl https://raw.githubusercontent.com/EngFlow/example/master/docs/goma/goma_server_patches.patch > goma_server_patches.patch
curl https://raw.githubusercontent.com/EngFlow/example/master/docs/goma/platform > platform
git clone https://chromium.googlesource.com/infra/goma/server goma_server
cd goma_server
git am ../goma_server_patches.patch
cd cmd/remoteexec_proxy
go build
./remoteexec_proxy \
    -exec-config-file ../../../platform \
    -allowed-users "*@localhost" \
    -remoteexec-addr oss-cluster.engflow.com:443 \
    -port 5050 \
    -remote-instance-name "unused" \
    -insecure-serveraccess \
    -tls-certificate ../../../engflow-ca.crt \
    -tls-client-certificate ../../../name@example.com.crt \
    -tls-client-key ../../../name@example.com.key
```

You can pass `-insecure-remoteexec` instead of `-tls-certificate` if you
disabled TLS server authentication, or you can drop the `-tls-client-*` options
if you disabled client authentication.

You need a second terminal window to continue as we are running the Goma remote
execution proxy in the foreground. The next step is to install the Goma client
(we use a precompiled binary for this):
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools depot_tools
cd depot_tools
./cipd install infra/goma/client/linux-amd64 ../goma_client/
```

Then, you need to configure the Goma client to connect to the Goma server. This
needs to be run in the directory where you installed the goma tools because it
uses `$(pwd)` below:
```
cd goma_client/
export GOMA_ARBITRARY_TOOLCHAIN_SUPPORT=true GOMA_USE_LOCAL=false \
    GOMA_USE_SSL=false GOMACTL_SKIP_AUTH=true GOMA_SERVER_HOST=localhost \
    GOMA_SERVER_PORT=5050 GOMA_FALLBACK=false CC="$(pwd)/gomacc gcc" \
    USER=me@localhost
```

We can now try connecting the Goma client to the Goma server:
```
./goma_ctl.py ensure_start
```

Finally, we can build something with Goma and remote execution:
```
sudo apt install libyaml-0-2 libyaml-dev
git clone --branch v1.1.0 https://github.com/tlsa/libcyaml.git libcyaml
cd libcyaml
make && make test
```

# Known Issues

1. `libcyaml` compiles against `libyaml-dev`, which is not installed in the
   image we use here.
