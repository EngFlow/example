# EngFlow Runfiles Libraries Demo

This is the example code for the EngFlow blog post &quot;[Migrating to Bazel
Modules (a.k.a. Bzlmod) - Repo Names and Runfiles][blog].&quot;

- `engflow` contains the main repository of the example
- `frobozz` is a separate Bazel module representing an external dependency

To try it out:

```sh
cd engflow
bazel run //:runfiles_demo
bazel build //:runfiles_genrule_demo &&
    cat bazel-bin/demo_output.txt
```

[blog]: https://blog.engflow.com/2024/08/09/migrating-to-bazel-modules-aka-bzlmod---repo-names-and-runfiles/
