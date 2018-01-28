#!/bin/bash
# TARGET_REPOSITORY env variable contains the base uri of the repo

PLATEFORME_NAME=$1
RELEASE_VERSION=$2
RELEASE_FILE_NAME=$3

usage() {
  echo "Requires some env variables to be setted : TARGET_REPOSITORY REPOSITORY_USERNAME REPOSITORY_PASSWORD"
  echo "usage is : $0 PLATEFORME_NAME RELEASE_VERSION RELEASE_FILE_NAME "
  exit 1
}

NETRC_FILENAME=.netrc-file

re='https?://([-A-Za-z0-9.]*)/.*'
if [[ "$TARGET_REPOSITORY" =~ $re ]] ;then
   REPOSITORY_MACHINE="${BASH_REMATCH[1]}"
else
  echo "Invalid TARGET_REPOSITORY $TARGET_REPOSITORY"
  exit 1
fi

createNetrcFile() {
cat << EOF > $NETRC_FILENAME
machine $REPOSITORY_MACHINE
login $REPOSITORY_USERNAME
password $REPOSITORY_PASSWORD
EOF
}

if [ -z "$TARGET_REPOSITORY" ];then echo "TARGET_REPOSITORY undefined" ; usage;fi
if [ -z "$REPOSITORY_USERNAME" ];then echo "REPOSITORY_USERNAME undefined" ; usage;fi
if [ -z "$REPOSITORY_PASSWORD" ];then echo "REPOSITORY_PASSWORD undefined" ; usage;fi

if [ $# -ne 3 ];then usage;fi

TARGET_URL=$TARGET_REPOSITORY$PLATEFORME_NAME/$RELEASE_VERSION/$RELEASE_FILE_NAME
RELEASE_FILE_PATH=$RELEASE_FILE_LOCATION/$RELEASE_FILE_NAME
CURRENT_DIR=`pwd`

createNetrcFile

curl --insecure --netrc-file $NETRC_FILENAME --head -i $TARGET_URL 2> /dev/null| grep "HTTP/1.1 404 Not Found"
PUBLISH_REQUIRED=$?

if [ "0" -eq "$PUBLISH_REQUIRED" ]; then
	echo "targeted release do not exist [$TARGET_URL]"
	exit 1
else
	curl -o $RELEASE_FILE_NAME --insecure --netrc-file $NETRC_FILENAME  $TARGET_URL
fi
rm $NETRC_FILENAME
