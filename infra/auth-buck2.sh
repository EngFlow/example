#!/usr/bin/env bash

# Modify the buck2/**/.buckconfig files to set the test cluster to opal.
find . -type f -name ".buckconfig" -exec sed -i 's/<CLUSTER_NAME>/opal/' {} \;

# Modify the buck2/**/.buckconfig files to set the "Authorization=Bearer $GITHUB_TOKEN" in the http_headers.
find . -type f -name ".buckconfig" sed -i 's/x-engflow-auth-method:jwt-v0,x-engflow-auth-token:LONG_JWT_STRING/Authorization=Bearer $GITHUB_TOKEN/' {} \;

# Testing only - remove before merging
cat buck2/cpp/.buckconfig
