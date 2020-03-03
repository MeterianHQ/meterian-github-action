#!/bin/bash -l

set -e
set -o pipefail

# check that the Meterian API token is correctly set
METERIAN_API_TOKEN=${METERIAN_API_TOKEN:?'METERIAN_API_TOKEN missing. Ensure that this secret is set correctly.'}

# prepare the script file
mv /root/meterian.sh /tmp/meterian.sh
export METERIAN_CLI_ARGS=$*

# create initialisation script (gradle)
echo "export PATH=${PATH}" >> /tmp/init.sh

# - add gradle specific configurations
echo "export GRADLE_HOME=/opt/gradle/gradle-6.1" >> /tmp/init.sh
echo "export PATH=\${GRADLE_HOME}/bin:\${PATH}" >> /tmp/init.sh
echo "export GRADLE_USER_HOME=~/.gradle" >> /tmp/init.sh

/tmp/meterian.sh