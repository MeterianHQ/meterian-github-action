#!/bin/bash

# Rust user-specific configuration setup
echo 'export RUSTUP_HOME=/opt/rust/rustup' >> ~/.bashrc
echo 'export PATH=${PATH}:/opt/rust/cargo/bin' >> ~/.bashrc
source ~/.bashrc

getLastModifiedDateTimeForFileInSeconds() {
	MAYBE_FILE=$1

	WHEN=`date -r $MAYBE_FILE +"%s" 2>/dev/null`
	if [[ $? > 0 ]]; then 
		WHEN="$(date -d "1999-01-01" +%s)"
	fi

	# returning the value of $WHEN ( common way of returning data from functions in bash )
	echo $WHEN
}

githubPrivateCustomConfig() {
	echo "machine github.com login "${MGA_GITHUB_USER}" password "${MGA_GITHUB_TOKEN}"" >> "${HOME}/.netrc"
}

bitbucketPrivateCustomConfig() {
	echo "machine bitbucket.org login "${MGA_BITBUCKET_USER}" password "${MGA_BITBUCKET_APP_PASSWORD}"" >> "${HOME}/.netrc"
	echo "machine api.bitbucket.org login "${MGA_BITBUCKET_USER}" password "${MGA_BITBUCKET_APP_PASSWORD}"" >> "${HOME}/.netrc"
}

gitlabPrivateCustomConfig() {
	echo "machine gitlab.com login "${MGA_GITLAB_USER}" password "${MGA_GITLAB_TOKEN}"" >> "${HOME}/.netrc"
}

privateVCConfigs() {
	if [[ -n "${MGA_GITHUB_USER:-}" && -n "${MGA_GITHUB_TOKEN}" ]]; then
		githubPrivateCustomConfig
	fi

	if [[ -n "${MGA_BITBUCKET_USER:-}" && -n "${MGA_BITBUCKET_APP_PASSWORD:-}" ]]; then
		bitbucketPrivateCustomConfig
	fi

	if [[ -n "${MGA_GITLAB_USER:-}" && -n "${MGA_GITLAB_TOKEN:-}" ]]; then
		gitlabPrivateCustomConfig
	fi
}

goVersionControlCustomConfig() {
	privateVCConfigs
}
goVersionControlCustomConfig

updateClient() {
	METERIAN_JAR_PATH=$1
	CLIENT_TARGET_URL=$2

	if [[ "${CLIENT_CANARY_FLAG:-}" == "--canary" ]];then
		CLIENT_TARGET_URL="https://www.meterian.com/downloads/meterian-cli-canary.jar"
	fi

	# LOCAL_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS=$(getLastModifiedDateTimeForFileInSeconds $METERIAN_JAR_PATH)
	# REMOTE_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS=$(date -d "$(curl -s -L -I "${CLIENT_TARGET_URL}" | grep Last-Modified: | cut -d" " -f2-)" +%s)
	# if [[ ${REMOTE_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS} -gt ${LOCAL_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS} ]];
	# then
	# 	echo Updating the client$(test -n "${CLIENT_CANARY_FLAG}" && echo " canary" || true)...
	# 	curl -s -o ${METERIAN_JAR_PATH} "${CLIENT_TARGET_URL}"  >/dev/null
	# fi
	echo "Checking client..."
	curl -s -o ${METERIAN_JAR_PATH} "${CLIENT_TARGET_URL}"  >/dev/null
}

# meterian jar location
METERIAN_JAR=/tmp/meterian-cli.jar

# update the client if necessary
updateClient "${METERIAN_JAR}" "https://www.meterian.com/downloads/meterian-cli.jar"

# Printing meterian dockerized client version
cat /tmp/version.txt 

# launching the client
java -Duser.home=/tmp $(echo "${CLIENT_VM_PARAMS:-} ${OSS_TRUE:-}")  -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS} --interactive=false

# please do not add any command here as we need to preserve the exit status
# of the meterian client