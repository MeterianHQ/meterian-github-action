#!/bin/bash

set -e
set -o pipefail

# check that the Meterian API token is correctly set
METERIAN_API_TOKEN=${METERIAN_API_TOKEN:?'METERIAN_API_TOKEN missing. Ensure that this secret is set correctly.'}

# prepare the script file
cp /root/meterian.sh /tmp/meterian.sh
export METERIAN_CLI_ARGS=$*

/tmp/meterian.sh
