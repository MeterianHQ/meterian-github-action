#!/bin/bash

set -e
set -o pipefail
set -x

# rust-specifics
chmod -R 777 /opt/rust/

export ORIGINAL_PATH=$PATH

OSS="$INPUT_OSS"
if [[ "$OSS" == "true" ]]; then
    export OSS_TRUE="-Dcli.oss.enabled=true"
else
    # check that the Meterian API token is correctly set
    METERIAN_API_TOKEN=${METERIAN_API_TOKEN:?'METERIAN_API_TOKEN missing. Ensure that this secret is set correctly.'}
fi

# prepare the script file and version file
cp /root/meterian.sh /tmp/meterian.sh
cp /root/version.txt /tmp/version.txt
cp /root/meterian-bot.py /tmp/meterian-bot.py
export METERIAN_CLI_ARGS="$INPUT_CLI_ARGS"

# ensuring that if the autofix is enabled the client produces the report.json file needed to know the autofix results
if [[ "${INPUT_AUTOFIX:-}" != "" ]];then
    export METERIAN_CLI_ARGS="$METERIAN_CLI_ARGS --autofix:${INPUT_AUTOFIX} --report-json=report.json"
fi

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
su meterian -c -m /tmp/meterian.sh #2> /dev/null
