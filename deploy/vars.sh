#!/bin/bash

## Edit this
if [ -z $DOCKER_IMAGE_NAME ]; then
    echo "DOCKER_IMAGE_NAME is not defined"
    exit 1;
fi

## Should not need to edit this
export DOCKER_HUB_NAME="metacpan/${DOCKER_IMAGE_NAME}"
export VERSION="${TRAVIS_BUILD_NUMBER:-UNKNOWN-BUILD-NUMBER}"
export VERSION_TAG="${DOCKER_HUB_NAME}:${VERSION}"

