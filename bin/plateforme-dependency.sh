#!/bin/bash

# Requiremnts file should look like this if a custom base_repository is desired
# base-repository=http://gqsdhlqjsdh.qsdqlsdhqsd/dzed.fr
# plateforme:0.0.1

# Requiremnts file should look like this if no custom base_repository 
# plateforme:0.0.1


ACTION=$1
REQUIREMENTS_FILE="required-plateforme"
BASE_WORKING_DIR="plateforme-workspace"
WORKING_DIR="${BASE_WORKING_DIR}"

LINE_NUMBER=0
REQUIRED_PLATEFORME=0
BASE_REPO=$PI_BUILD_SCRIPT_DEFAULT_PLATEFORME_BASE_REPO


import(){
  echo "Importing Plateforme Requirements using $PI_BUILD_SCRIPT_DIR"
  
  if  [ ! -d $WORKING_DIR ]; then mkdir -p $WORKING_DIR; fi
  
  echo "Verify plateforme requirements format..."
  req_file=$REQUIREMENTS_FILE
  if ! diff $REQUIREMENTS_FILE <(awk -F: '  { print $1":"$2 } ' $REQUIREMENTS_FILE) ; then
     echo "ERROR: $REQUIREMENTS_FILE syntax or format error!"
     cat -e $REQUIREMENTS_FILE
     exit 1
  fi

  echo  "Downloading plateforme requirements ..."
  echo "$REQUIREMENTS_FILE"
  while  read -r line
  do
           re="^(base-repository=)(.*)$"
           if [[ $LINE_NUMBER -eq 0 ]] && [[ "$line" =~ $re ]] ;then
                   BASE_REPO="${BASH_REMATCH[2]}";
                   echo "Using custom base repo is $BASE_REPO"
           else
                   if [[ $LINE_NUMBER -eq 0 ]] && [[ "$line" =~ $re ]] ;
                           then echo "Using default base repo $BASE_REPO";
                   fi
                   echo "requires $line"
                   re="^([^:]+):(.*)$"
                   if [[ "$line" =~ $re ]] ;then
                           PLATEFORME_NAME="${BASH_REMATCH[1]}" && PLATEFORME_VERSION="${BASH_REMATCH[2]}"
                   else
                           echo "$line is not a valid requirement"
                           exit 1
                   fi
                   REQUIRED_FILE=$PLATEFORME_NAME-$PLATEFORME_VERSION.tar.gz
                   TARGET_URL=$BASE_REPO$PLATEFORME_NAME/$PLATEFORME_VERSION/$REQUIRED_FILE
                   echo "downloading : $TARGET_URL"
                   curl --insecure --head -i $TARGET_URL 2> /dev/null| grep "HTTP/1.1 200 OK"
                   REQUIRED_EXISTS=$?
		   if [ $REQUIRED_EXISTS -eq 0 ]; then
                     curl -L -v -s -k -o $WORKING_DIR/$REQUIRED_FILE $TARGET_URL 2> /dev/null
                   else
                     echo "Missing dependency on [$line]"
                     echo "$TARGET_URL does not exist !!!!"
                   fi 
                   ((REQUIRED_PLATEFORME++))
           fi
           ((LINE_NUMBER++))
  done  < "$REQUIREMENTS_FILE"
  echo  "[ $REQUIRED_PLATEFORME ] plateforme required"
  if [ ! $REQUIRED_PLATEFORME -eq 1 ]; then echo "Only one plateforme should be required"; exit 1; fi
}

package(){
  echo "packaging : $REQUIREMENTS_FILE"
  for plateforme_archive in $WORKING_DIR/*; do
   tar xvfz $plateforme_archive -C dist
  done
}

clean() {
  echo "Cleaning Plateforme Requirements "
  if  [ -d $WORKING_DIR ]; then rm -rf $WORKING_DIR; fi

}

case "$ACTION" in
	"import")
		import ;;
	"package")
		package	;;
	"clean")
		clean ;;
	*)
		echo "Unknown action [$ACTION]" ;;
esac
