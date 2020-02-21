#!/bin/bash

set -e
set -o pipefail

# prepare the script file
mv /root/meterian.sh /tmp/meterian.sh
mv /root/version.txt /tmp/version.txt
export METERIAN_CLI_ARGS=$*

# create initialisation script (gradle)
echo "export PATH=${PATH}" >> /tmp/init.sh

# - add gradle specific configurations
echo "export GRADLE_HOME=/opt/gradle/gradle-6.1" >> /tmp/init.sh
echo "export PATH=\${GRADLE_HOME}/bin:\${PATH}" >> /tmp/init.sh
echo "export GRADLE_USER_HOME=~/.gradle" >> /tmp/init.sh

# run the script binding the user if required
if [ "${HOST_UID}" == "" ];
then
    /tmp/meterian.sh 2>/dev/null

    # please do not add any command here as we need to preserve the exit status
    # of the meterian client
else
    # create the user
    groupadd -g ${HOST_GID} meterian
    useradd -g meterian -u ${HOST_UID} meterian -d /home/meterian

    # creating home dir if it doesn't exist
    if [ ! -d "/home/meterian" ];
    then
        mkdir /home/meterian
    fi

    #changing home dir group and ownership
    chown meterian:meterian /home/meterian

    # launch meterian client with the newly created user
    su meterian -c -m /tmp/meterian.sh  2>/dev/null

    # please do not add any command here as we need to preserve the exit status
    # of the meterian client
fi

# please do not add any command here as we need to preserve the exit status
# of the meterian client
