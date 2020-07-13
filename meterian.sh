#!/bin/bash

getLastModifiedDateForFile() {
	MAYBE_FILE=$1

	WHEN=`date -r $MAYBE_FILE +"%Y-%m-%d" 2>/dev/null`
	if [[ $? > 0 ]]; then 
		WHEN='1999-01-01'
	fi

	# returning the value of $WHEN ( common way of returning data from functions in bash )
	echo $WHEN
}

updateClient() {
	METERIAN_JAR_PATH=$1
	CLIENT_TARGET_URL=$2

	LOCAL_CLIENT_LAST_MODIFIED_DATE=$(getLastModifiedDateForFile $METERIAN_JAR_PATH)
	REMOTE_CLIENT_LAST_MODIFIED_DATE=$(date -d "$(curl -s -L -I "${CLIENT_TARGET_URL}" \
									| grep Last-Modified: | cut -d" " -f2-)" +%F)
	if [[ "${REMOTE_CLIENT_LAST_MODIFIED_DATE}" > "${LOCAL_CLIENT_LAST_MODIFIED_DATE}" ]];
	then
		echo Updating the client$(test -n "${CLIENT_CANARY_FLAG}" && echo " canary" || true)...
		curl -s -o ${METERIAN_JAR_PATH} "${CLIENT_TARGET_URL}"  >/dev/null
	fi
}

# meterian jar location
METERIAN_JAR=/meterian-cli.jar

# update the client if necessary
updateClient "${METERIAN_JAR}" "https://www.meterian.com/downloads/meterian-cli.jar"

# Printing meterian dockerized client version
cat /root/version.txt 

# launching the client
java -Duser.home=/tmp  -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS} --interactive=false

# please do not add any command here as we need to preserve the exit status
# of the meterian client