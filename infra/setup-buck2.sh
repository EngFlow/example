#!/usr/bin/env bash
set -xe

# Get the Buck2 binary - using latest
curl -L -O https://github.com/facebook/buck2/releases/download/latest/buck2-x86_64-unknown-linux-musl.zst

# Unpack the binary.
unzstd buck2-x86_64-unknown-linux-musl.zst

# Change its name and make it executable.
mv buck2-x86_64-unknown-linux-musl buck2-exe
chmod +x buck2-exe
