#!/usr/bin/env bash
set -x

touch .bazelrc.user
echo 'build:opal_auth --remote_header=\"Authorization=Bearer $GITHUB_TOKEN\"' >> .bazelrc.user
cat .bazelrc.user


echo "$GITHUB_TOKEN" | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
docker inspect ghcr.io/engflow/hello-world:1.0
