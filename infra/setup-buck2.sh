#!/usr/bin/env bash
set -xe

# Get the Buck2 binary - pinned to https://github.com/facebook/buck2/releases/tag/2025-05-06
curl -L -O https://github.com/facebook/buck2/releases/download/2025-05-06/buck2-x86_64-unknown-linux-musl.zst

# Unpack the binary.
unzstd buck2-x86_64-unknown-linux-musl.zst

# Change its name and make it executable.
mv buck2-x86_64-unknown-linux-musl buck2-exe
chmod +x buck2-exe

# Alternatively, for a platform-independent method that requires building from source:
# Install the specific nightly version
# rustup install nightly-2025-02-16

# Use that specific version to install Buck2
# cargo +nightly-2025-02-16 install --git https://github.com/facebook/buck2 --rev 201beb86106fecdc84e30260b0f1abb5bf576988 buck2