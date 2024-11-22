#!/usr/bin/env bash
set -x

# Modify the buck2/**/.buckconfig files to set the test cluster to opal.
find ./ -type f -name '.buckconfig' -exec sed -i 's/<CLUSTER_NAME>/opal/g' {} \;

# Modify the buck2/**/.buckconfig files to set the "Authorization=Bearer $GITHUB_TOKEN" in the http_headers.
find ./ -type f -name '.buckconfig' -exec sed -i 's/x-engflow-auth-method:jwt-v0,x-engflow-auth-token:LONG_JWT_STRING/Authorization=Bearer $GITHUB_TOKEN/g' {} \;

