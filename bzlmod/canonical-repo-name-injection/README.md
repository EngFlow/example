# Canonical Repo Name Injection Demo

This is the example code for the EngFlow blog post &quot;[Migrating to Bazel
Modules (a.k.a. Bzlmod) - Repo Names, Macros, and Variables][blog].&quot;

To try it out:

```sh
bazel build //:repo-macros && cat bazel-bin/repo-macros.txt
bazel build //:repo-vars && cat bazel-bin/repo-vars.txt
bazel run //:repo-dir-check
cat bazel-bin/genrule-constants.js
vimdiff bazel-bin/{genrule,}-constants.js
bazel run --//:constants=custom-rule //:repo-dir-check
cat bazel-bin/custom-rule-constants.js
vimdiff bazel-bin/{genrule,custom-rule}-constants.js
node bazel-bin/repo-dir-check.mjs
```

[blog]: https://blog.engflow.com/2024/09/06/migrating-to-bazel-modules-aka-bzlmod---repo-names-macros-and-variables/
