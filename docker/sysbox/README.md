# Preparing your code base for Remote Execution

This is an example project that validates Sysbox setup for your EngFlow cluster
works correctly.

Use as companion to https://docs.engflow.com/re/client/sysbox.html

Usage:

- Follow instructions in https://docs.engflow.com/re/client/sysbox.html to generate
 a container tha uses `sysbox` to run nested docker containers.

- Modify the `dind_test/BUILD`. Change the `container-image` attribute of the `sh_test`
rule to point the container you produced in the previous step.

- Modify the `.bazelrc` file at the top level of the repo to use your own endpoint.

- Run the following command:

```sh
bazel test --config=<your-cluster> --test_output=all //docker/sysbox/dind_test:check_docker
```

# How does it work?

The simple `sh_test` will run remotely using the container you produced following
the instructions in the docs pointed above. The remote worker will attempt to pull and
run your container and run the `sh_test` inside of the container. The `sh_test` rule
starts an container using an alpine image and runs a date command in the container.
Note if your cluster does not have access to this image you can replace it in the
`dind_test/check_docker.sh` to use any image that is accessible from your cluster.

If your container can be initiated without issues using the `sysbox-runc` example
the it is properly configured and ready to use for your DinD needs.

