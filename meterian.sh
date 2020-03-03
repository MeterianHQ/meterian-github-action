#!/bin/bash

# executing general initialisation script
#cat /tmp/init.sh
source /tmp/init.sh

# meterian jar location
METERIAN_JAR=/meterian-cli.jar

# update the client if necessary
LOCAL_CLIENT_LAST_MODIFIED_DATE=$(date -d "$(ls --full-time ${METERIAN_JAR} | cut -d" " -f6-8)" +%F)
REMOTE_CLIENT_LAST_MODIFIED_DATE=$(date -d "$(curl -s -L -I "https://www.meterian.com/downloads/meterian-cli.jar" \
   								   | grep Last-Modified: | cut -d" " -f2-)" +%F)
if [[ "${REMOTE_CLIENT_LAST_MODIFIED_DATE}" > "${LOCAL_CLIENT_LAST_MODIFIED_DATE}" ]];
then
	echo Updating the client...
	curl -s -o ${METERIAN_JAR} "https://www.meterian.com/downloads/meterian-cli.jar"  >/dev/null
fi

# launching the client
java -Duser.home=/tmp  -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS} --interactive=false

# please do not add any command here as we need to preserve the exit status
# of the meterian client