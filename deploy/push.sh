#!/bin/bash

DEPLOY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${DEPLOY_DIR}/vars.sh"

cd "${DEPLOY_DIR}/.."

docker login -u "$DOCKER_HUB_USER" -p "$DOCKER_HUB_PASSWD"

docker push "$DOCKER_HUB_NAME"