#!/bin/sh

set -e

CURRENT_PATH=$(dirname "$0")
bash ${CURRENT_PATH}/sanity.sh api.thiago.pub
