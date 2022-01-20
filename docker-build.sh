#!/bin/sh

set -e

. scripts/clean.sh
docker build "$@" . -t spaceapi-v`date +"%Y%m%d%H%M%S"`
