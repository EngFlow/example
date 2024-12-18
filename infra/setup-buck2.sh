#!/usr/bin/env bash
set -xe

# Get the Buck2 binary - pinned to https://github.com/facebook/buck2/releases/tag/2024-12-16
curl -L -O https://github.com/facebook/buck2/releases/download/2024-12-16/buck2-x86_64-unknown-linux-musl.zst

# Unpack the binary.
unzstd buck2-x86_64-unknown-linux-musl.zst

# Change its name and make it executable.
mv buck2-x86_64-unknown-linux-musl buck2-exe
chmod +x buck2-exe
