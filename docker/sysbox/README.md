# Preparing your code base for Remote Execution

This is an example project that validates Sysbox setup for your EngFlow cluster
works correctly.

Use as companion to https://docs.engflow.com/re/client/sysbox.html

Usage:

- Follow instructions in https://docs.engflow.com/re/client/sysbox.html to generate
 your DinD container.

- Modify the `genrules/BUILD`. Change the `container-image` attribute of the simple `genrule`
to point the container you produced in the previous step. 

- Modify the `.bazelrc` file config `<your-cluster>` to use your own endpoint 

- Run the following command:

```sh
bazel build --config=<your-cluster> //genrules/...
```

# How does it work?

The simple `genrule` will run remotely using the DinD container you produced following
the instructions in the docs pointed above. The remote worker will attempt to pull and
run your DinD container and run the `genrule` inside of the container. If your container
can be initiated without issues using the `sysbox-runc` example the it is properly
configured and ready to use for your DinD needs.

