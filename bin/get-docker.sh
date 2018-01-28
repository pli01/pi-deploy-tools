#!/bin/bash

display_help() {
    echo "Usage: $0 image_name tag" >&2
    echo
    echo "example : $0 debian-base latest"
    exit 1
}

if [ "$1" == "--help" ]; then
	display_help 
	exit 0;
fi

if [ "$#" -ne 2 ]; then
	display_help 
	exit -1;
fi
IMAGE_NAME=$1
TAG=$2
DOCKER_PI_REGISTRY_LOGIN=$REPOSITORY_USERNAME
DOCKER_PI_REGISTRY_PASSWORD=$REPOSITORY_PASSWORD

DOCKER_PI_REGISTRY=$PI_BUILD_SCRIPT_DML_FDQN

docker login -u $DOCKER_PI_REGISTRY_LOGIN -p $DOCKER_PI_REGISTRY_PASSWORD $DOCKER_PI_REGISTRY
docker pull $DOCKER_PI_REGISTRY/$IMAGE_NAME:$TAG
