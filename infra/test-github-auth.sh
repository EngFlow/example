#!/usr/bin/env bash
set -x

touch .bazelrc.user
echo 'build:opal_auth --remote_header=\"Authorization=Bearer $GITHUB_TOKEN\"' >> .bazelrc.user
cat .bazelrc.user
