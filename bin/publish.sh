#!/bin/bash
# TARGET_REPOSITORY env variable contains the base uri of the repo

PLATEFORME_NAME=$1
RELEASE_VERSION=$2
RELEASE_FILE_NAME=$3
RELEASE_FILE_LOCATION=$4
PUBLISH_STABLE="stable"

usage() {
  echo "Requires some env variables to be setted : TARGET_REPOSITORY REPOSITORY_USERNAME REPOSITORY_PASSWORD"
  echo "usage is : $0 PLATEFORME_NAME RELEASE_VERSION RELEASE_FILE_NAME RELEASE_FILE_LOCATION"
  exit 1
}

NETRC_FILENAME=.netrc-file
STABLE_NAME="stable"

REPOSITORY_MACHINE="$PI_BUILD_SCRIPT_DML_FDQN"
REPOSITORY_MACHINE_SYNC="$PI_BUILD_SCRIPT_DML_FDQN_SYNC"

createNetrcFile() {
cat << EOF > $NETRC_FILENAME
machine $REPOSITORY_MACHINE
login $REPOSITORY_USERNAME
password $REPOSITORY_PASSWORD

machine $REPOSITORY_MACHINE_SYNC
login $REPOSITORY_USERNAME
password $REPOSITORY_PASSWORD
EOF
}

if [ -z $TARGET_REPOSITORY ];then echo "TARGET_REPOSITORY undefined" ; usage;fi
if [ -z $REPOSITORY_USERNAME ];then echo "REPOSITORY_USERNAME undefined" ; usage;fi
if [ -z $REPOSITORY_PASSWORD ];then echo "REPOSITORY_PASSWORD undefined" ; usage;fi

if [ $# -ne 4 ];then usage;fi

TARGET_URL="$PI_BUILD_SCRIPT_DML_REPOSITORY_URL/$TARGET_REPOSITORY/$PLATEFORME_NAME/$RELEASE_VERSION/$RELEASE_FILE_NAME"
TARGET_URL_SYNC="$PI_BUILD_SCRIPT_DML_REPOSITORY_URL_SYNC/$TARGET_REPOSITORY/$PLATEFORME_NAME/$RELEASE_VERSION/$RELEASE_FILE_NAME"
STABLE_RELEASE_FILE_NAME=`echo $RELEASE_FILE_NAME | sed -e "s/$RELEASE_VERSION/$STABLE_NAME/g"`
STABLE_TARGET_URL="$PI_BUILD_SCRIPT_DML_REPOSITORY_URL/$TARGET_REPOSITORY/$PLATEFORME_NAME/$STABLE_NAME/$STABLE_RELEASE_FILE_NAME"
STABLE_TARGET_URL_SYNC="$PI_BUILD_SCRIPT_DML_REPOSITORY_URL_SYNC/$TARGET_REPOSITORY/$PLATEFORME_NAME/$STABLE_NAME/$STABLE_RELEASE_FILE_NAME"
RELEASE_FILE_PATH=$RELEASE_FILE_LOCATION/$RELEASE_FILE_NAME
CURRENT_DIR=`pwd`

createNetrcFile

curl --insecure --netrc-file $NETRC_FILENAME --head -i $TARGET_URL 2> /dev/null| grep "HTTP/1.1 404"
PUBLISH_REQUIRED=$?

re="^.*-SNAPSHOT$"
if [[ "$RELEASE_VERSION" =~ $re ]]; then
        echo "Force publishing of the SNAPSHOT VERSION : $RELEASE_VERSION"
	PUBLISH_REQUIRED=0
fi

if [ "0" -eq $PUBLISH_REQUIRED ]; then
        echo "CREATING MD5 SUM file for $RELEASE_FILE_NAME"
        cd $RELEASE_FILE_LOCATION && md5sum $RELEASE_FILE_NAME > $CURRENT_DIR/$RELEASE_FILE_NAME".md5" && cd $CURRENT_DIR
        echo -e "PUBLISHING $RELEASE_FILE_PATH AT $TARGET_URL"
        curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_PATH $TARGET_URL | grep "HTTP/1.1 201"
        PUBLISH_STATUS=$?
        if [ "0" -ne $PUBLISH_STATUS ]; then
                echo -e "FAIL TO PUBLISH $RELEASE_FILE_PATH AT $TARGET_URL"
                exit 1
        fi
	if [ "1" -eq "$SYNC_ENABLED" ];then
		curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_PATH $TARGET_URL_SYNC
	fi
        curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_NAME".md5" $TARGET_URL".md5" | grep "HTTP/1.1 201"
        PUBLISH_STATUS=$?
        if [ "0" -ne $PUBLISH_STATUS ]; then
                echo -e "WARN : FAIL TO PUBLISH $RELEASE_FILE_NAME.md5 AT $TARGET_URL.md5"
        fi
	if [ "1" -eq "$SYNC_ENABLED" ];then
		curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_NAME".md5" $TARGET_URL_SYNC".md5"
	fi
        echo -e "$RELEASE_FILE_PATH PUBLISHED AT $TARGET_URL"

	# TODO: refactor and use a function instead of this duplicated code
	if [ "stable" == "$PUBLISH_STABLE" ]; then
	        echo -e "PUBLISHING STABLE AT $STABLE_TARGET_URL"
	        curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_PATH $STABLE_TARGET_URL | grep "HTTP/1.1 201"
	        PUBLISH_STATUS=$?
	        if [ "0" -ne $PUBLISH_STATUS ]; then
	                echo -e "FAIL TO PUBLISH $RELEASE_FILE_PATH AT $STABLE_TARGET_URL"
	                exit 1
	        fi
		if [ "1" -eq "$SYNC_ENABLED" ];then
			curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_PATH $STABLE_TARGET_URL_SYNC
		fi
	        curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_NAME".md5" $STABLE_TARGET_URL".md5" | grep "HTTP/1.1 201"
	        PUBLISH_STATUS=$?
	        if [ "0" -ne $PUBLISH_STATUS ]; then
	                echo -e "WARN : FAIL TO PUBLISH $RELEASE_FILE_NAME.md5 AT $STABLE_TARGET_URL.md5"
	        fi
		if [ "1" -eq "$SYNC_ENABLED" ];then
			curl -i --insecure --netrc-file $NETRC_FILENAME --upload-file $RELEASE_FILE_NAME".md5" $STABLE_TARGET_URL_SYNC".md5"
		fi
	        rm $RELEASE_FILE_NAME".md5"
		echo -e "$RELEASE_FILE_PATH PUBLISHED AT $STABLE_TARGET_URL"
	fi
        rm $RELEASE_FILE_NAME".md5"
else
        echo -e "$RELEASE_FILE_PATH IS ALREADY PUBLISHED AT $TARGET_URL"
	rm $NETRC_FILENAME
	exit 1
fi
rm $NETRC_FILENAME
