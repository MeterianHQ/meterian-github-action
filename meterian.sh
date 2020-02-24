#!/bin/bash

# executing general initialisation script
#cat /tmp/init.sh
source /tmp/init.sh

exitWithErrorMessageWhenApiTokenIsUnset() {
	if [[ -z "${METERIAN_API_TOKEN:-}" ]] 
	then
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo " METERIAN_API_TOKEN environment variable must be defined with a valid API token "
		echo " Please create a token from your account at https://meterian.com/account/       "
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-"
		exit -1
	fi
}

INDEPENDENT_METERIAN_CLI_OPTIONS="(--version|--help)"

# dump docker packaged version unless '--version' requested
if [[ ! ${METERIAN_CLI_ARGS} =~ ${INDEPENDENT_METERIAN_CLI_OPTIONS} ]]; then
    cat /tmp/version.txt
	exitWithErrorMessageWhenApiTokenIsUnset
fi

# meterian jar location
METERIAN_JAR=/tmp/meterian-cli.jar

# update the client if necessary
if [[ ! -f ${METERIAN_JAR} ]];
then
	mv /meterian-cli.jar /tmp/
fi

LOCAL_CLIENT_LAST_MODIFIED_DATE=$(date -d "$(ls --full-time ${METERIAN_JAR} | cut -d" " -f6-8)" +%F)
REMOTE_CLIENT_LAST_MODIFIED_DATE=$(date -d "$(curl -s -L -I "https://www.meterian.com/downloads/meterian-cli.jar" \
   								   | grep Last-Modified: | cut -d" " -f2-)" +%F)
if [[ "${REMOTE_CLIENT_LAST_MODIFIED_DATE}" > "${LOCAL_CLIENT_LAST_MODIFIED_DATE}" ]];
then
	echo Updating the client...
	curl -s -o ${METERIAN_JAR} "https://www.meterian.com/downloads/meterian-cli.jar"  >/dev/null
fi

# launching the client - note the different launch if version requested to preserve the "--version" base functionality
if [[ -n "${METERIAN_API_TOKEN:-}" || ${METERIAN_CLI_ARGS} =~ ${INDEPENDENT_METERIAN_CLI_OPTIONS} ]];
then
	java -Duser.home=/tmp  -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS}
fi

# setting the GitHub action output parameter
echo ::set-output name=exit_code::$?

# dump docker packaged version, and eventually related error messages, right after the client version
if [[ ${METERIAN_CLI_ARGS} =~ ${INDEPENDENT_METERIAN_CLI_OPTIONS} ]];then
    cat /tmp/version.txt        # 0 exit code but it's okay

	exitWithErrorMessageWhenApiTokenIsUnset
fi

exit 0

# please do not add any command here as we need to preserve the exit status
# of the meterian client