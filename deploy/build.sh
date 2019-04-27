#!/bin/bash

DEPLOY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${DEPLOY_DIR}/vars.sh"

# ## Go to where the docker file is
cd "${DEPLOY_DIR}/.."

## Pull the latest docker file from docker hub if there is one
docker pull "$DOCKER_HUB_NAME" || true

## Issue the build command, adding tags (from CONFIG.sh)
docker build --pull --cache-from "$DOCKER_HUB_NAME" --tag $DOCKER_HUB_NAME --tag $VERSION_TAG .
