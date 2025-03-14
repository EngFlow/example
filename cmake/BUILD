load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")
load("@rules_python//python:features.bzl", "features")

cmake(
    name = "pcre",
    cache_entries = {
        "CMAKE_C_FLAGS": "-fPIC",
    },
    lib_source = "@pcre//:all_srcs",
    out_static_libs = ["libpcre.a"],
)