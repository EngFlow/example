#!/usr/bin/env bash
set -x

touch .bazelrc.user
echo 'Authorization=Bearer $GITHUB_TOKEN' >> .bazelrc.user
