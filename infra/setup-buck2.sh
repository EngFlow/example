#!/usr/bin/env bash
set -x

# Build zstd: Remove once zstd is insalled in CI runner.
git clone https://github.com/facebook/zstd.git
cd zstd/build/cmake
cmake .
make
cd ../../../

# Get the Buck2 binary.
wget https://github.com/facebook/buck2/releases/download/latest/buck2-aarch64-unknown-linux-gnu.zst

# Unpack the binary.
# Use installed zstd once available in the CI runner.
zstd/build/cmake/programs/zstd -d buck2-aarch64-unknown-linux-gnu.zst
# unzstd buck2-aarch64-unknown-linux-gnu.zst

# Change its name and make it executable.
mv buck2-aarch64-unknown-linux-gnu.zst buck2
chmod +x buck2
