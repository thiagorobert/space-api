#!/bin/sh

set -e

LATEST_IMAGE=${1:-`docker images | awk '{ print $1; }' | grep spaceapi | head -1`}

echo "Running latest image: $LATEST_IMAGE"

#docker run -p 8080:8080 -p 8081:8081 -p 9090:9090 -p 9091:9091 -ti --rm $LATEST_IMAGE
docker run -p 9091:9091 -p 8081:8081 -p 9090:9090 -ti --rm $LATEST_IMAGE
