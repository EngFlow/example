#!/usr/bin/env bash
set -x

# Build zstd: Remove once zstd is insalled in CI runner.
git clone https://github.com/facebook/zstd.git
cd zstd/
make
cd ../

# Get the Buck2 binary.
curl --output buck2-aarch64-unknown-linux-gnu.zst https://github.com/facebook/buck2/releases/download/latest/buck2-aarch64-unknown-linux-gnu.zst

# Unpack the binary.
# Use installed zstd once available in the CI runner.
./zstd/zstd -d buck2-aarch64-unknown-linux-gnu.zst
# unzstd buck2-aarch64-unknown-linux-gnu.zst

# Change its name and make it executable.
mv buck2-aarch64-unknown-linux-gnu.zst buck2-exe
chmod +x buck2-exe
