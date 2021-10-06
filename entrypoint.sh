#!/bin/bash

set -e
set -o pipefail

# rust-specifics
chmod -R 777 /opt/rust/

export ORIGINAL_PATH=$PATH

OSS="$2"
if [[ "$OSS" == "true" ]]; then
    export OSS_TRUE="-Dcli.oss.enabled=true"
else
    # check that the Meterian API token is correctly set
    METERIAN_API_TOKEN=${METERIAN_API_TOKEN:?'METERIAN_API_TOKEN missing. Ensure that this secret is set correctly.'}
fi

# prepare the script file and version file
cp /root/meterian.sh /tmp/meterian.sh
cp /root/version.txt /tmp/version.txt
export METERIAN_CLI_ARGS="$1"

# creating user meterian necessary for dependency management tools that require it (e.g. cocoapods)
currDir=$(pwd)
WITH_HUID="-ou $(stat -c '%u' "${currDir}")"
WITH_HGID="-g $(stat -c '%g' "${currDir}") -o"

groupadd ${WITH_HGID} meterian
useradd -g meterian ${WITH_HUID} meterian -d /home/meterian

# creating home dir if it doesn't exist
if [[ ! -d "/home/meterian" ]];
then
    mkdir /home/meterian
fi

# changing home dir group and ownership
chown meterian:meterian /home/meterian

# launch meterian client with the newly created user
su meterian -c -m /tmp/meterian.sh 2> /dev/null
