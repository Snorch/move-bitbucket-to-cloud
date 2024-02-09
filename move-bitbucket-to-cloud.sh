#!/bin/bash
#
#This script reads .config to use your data to connect to git server and
#bitbucket.org. Then for each repository name in .repositories file it
#clones the repo locally from your git server and creates repo with the
#same name on bitbucket.org in you workspace/project, then it syncs the
#repository to bitbucket.org.
#
#It is assumed that all needed ssh keys are already setup beforehand.
#
# note: You must edit .config with your values first
source .config

TMPDIR=$(mktemp -d move-bitbucket-to-cloud-XXXXXX)
cd $TMPDIR

function bitbucket-create-repo {
	CREATE_REPO=$1
	curl -sS --location --fail -i -X POST \
		-u "$BITBUCKET_USER_NAME:$BITBUCKET_APP_PASS" \
		-H "Content-Type: application/json" \
		-d "{ \"scm\": \"git\", \"is_private\": \"1\", \"project\": {\"key\": \"$BITBUCKET_PROJECT_KEY\"} }" \
		"https://api.bitbucket.org/2.0/repositories/$BITBUCKET_WORKSPACE/{$CREATE_REPO}" &> /dev/null
	if [ "$?" != "0" ]; then
		echo "Failed to create repo $CREATE_REPO"
	fi
}

set -e

for REPO in $(cat ../.repositories); do
	git clone "$FROM_REPO_PREFIX$REPO.git" --mirror "$REPO"
	cd $REPO
	bitbucket-create-repo $REPO
	git remote add neworigin "$BITBUCKET_REPO_PREFIX$REPO.git"
	git push neworigin --mirror
	cd ..
	rm -rf $REPO
done

cd ..
rm -rf $TMPDIR
