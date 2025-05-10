# Former `rules_scala` module extensions directory

We removed the [module extensions][] from this directory after the release of
[rules_scala v7.0.0][], which supports [Bazel modules (a.k.a. Bzlmod)][Bzlmod]
directly. We also removed the patch for `rules_scala` v6.6.0 from this
directory's parent.

[Migrating to Bazel Modules (a.k.a. Bzlmod) - Module Extensions][post] from the
[EngFlow 'bzlmod' blog post series][series] describes the former extensions and
their configuration in detail. You can also see the previous files in the git
history at commit `79b5193`:

- [MODULE.bazel](https://github.com/EngFlow/example/blob/79b51930e4629486462c0f9787a25d035b6c4450/MODULE.bazel#L167-L317)
- [scala/extensions/config.bzl](https://github.com/EngFlow/example/blob/79b51930e4629486462c0f9787a25d035b6c4450/scala/extensions/config.bzl)
- [scala/extensions/deps.bzl](https://github.com/EngFlow/example/blob/79b51930e4629486462c0f9787a25d035b6c4450/scala/extensions/deps.bzl)
- [scala/rules_scala-6.6.0.patch](https://github.com/EngFlow/example/blob/79b51930e4629486462c0f9787a25d035b6c4450/scala/rules_scala-6.6.0.patch)

You can view these files locally using:

```txt
git show 79b5193:MODULE.bazel
git show 79b5193:scala/extensions/config.bzl
git show 79b5193:scala/extensions/deps.bzl
git show 79b5193:scala/rules_scala-6.6.0.patch
```

To see the content of the `scala/extensions` at that commit:

```sh
$ git show 79b5193:scala/extensions
tree 79b5193:scala/extensions

BUILD
config.bzl
deps.bzl
```

[Bzlmod]: https://bazel.build/external/module
[module extensions]: https://bazel.build/external/extension
[rules_scala v7.0.0]: https://github.com/bazel-contrib/rules_scala/releases/tag/v7.0.0
[post]: https://blog.engflow.com/2025/01/16/migrating-to-bazel-modules-aka-bzlmod---module-extensions/
[series]: https://blog.engflow.com/category/bzlmod/
