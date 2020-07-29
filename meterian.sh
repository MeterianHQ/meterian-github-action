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

githubCustomConfig() {
	export GOPRIVATE="github.com/${MGA_GITHUB_USER}"
	git config \
	--global \
	url."https://${MGA_GITHUB_USER}:${MGA_GITHUB_TOKEN}@github.com".insteadOf \
	"https://github.com"
}

versionControlCustomConfig() {
	if [[ -n "${MGA_GITHUB_USER:-}" && -n "${MGA_GITHUB_TOKEN}" ]]; then
		githubCustomConfig
	fi
}
versionControlCustomConfig

updateClient() {
	METERIAN_JAR_PATH=$1
	CLIENT_TARGET_URL=$2

	if [[ "${CLIENT_CANARY_FLAG:-}" == "--canary" ]];then
		CLIENT_TARGET_URL="https://www.meterian.com/downloads/meterian-cli-canary.jar"
	fi

	echo "Listing the client jar pre-update"
	ls -lat ${METERIAN_JAR_PATH}
	LOCAL_CLIENT_LAST_MODIFIED_DATE=$(getLastModifiedDateForFile $METERIAN_JAR_PATH)
	REMOTE_CLIENT_LAST_MODIFIED_DATE=$(date -d "$(curl -s -L -I "${CLIENT_TARGET_URL}" \
									| grep Last-Modified: | cut -d" " -f2-)" +%F)
	if [[ "${REMOTE_CLIENT_LAST_MODIFIED_DATE}" > "${LOCAL_CLIENT_LAST_MODIFIED_DATE}" ]];
	then
		echo Updating the client$(test -n "${CLIENT_CANARY_FLAG}" && echo " canary" || true)...
		rm -f ${METERIAN_JAR_PATH}
		curl -s -o ${METERIAN_JAR_PATH} "${CLIENT_TARGET_URL}"  >/dev/null
		echo "Listing the client jar post-update"
		ls -lat ${METERIAN_JAR_PATH}
	fi
}

# meterian jar location
METERIAN_JAR=/meterian-cli.jar

# update the client if necessary
set -x
updateClient "${METERIAN_JAR}" "https://www.meterian.com/downloads/meterian-cli.jar"
set +x

# Printing meterian dockerized client version
cat /tmp/version.txt 

# launching the client
java -Duser.home=/tmp "${CLIENT_VM_PARAMS:-}" -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS} --interactive=false

# please do not add any command here as we need to preserve the exit status
# of the meterian client