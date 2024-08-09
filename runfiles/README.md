# EngFlow Runfiles Libraries Demo

This is an example repository for an upcoming EngFlow blog post, &quot;Migrating
to Bazel Modules (a.k.a. Bzlmod) - Repo Names and Runfiles&quot;.

- `engflow` contains the main repository of the example
- `frobozz` is a separate Bazel module representing an external dependency

To try it out:

```sh
cd engflow
bazel run //:runfiles_demo
bazel build //:runfiles_genrule_demo &&
    cat bazel-bin/demo_output.txt
```
