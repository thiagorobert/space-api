#!/bin/sh

set -e

docker build "$@" . -t spaceapi-v`date +"%Y%m%d%H%M%S"`
