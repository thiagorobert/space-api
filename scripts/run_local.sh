#!/bin/sh

set -e

CLEAN="${1:-noclean}"

if [ ${CLEAN} != "noclean" ]; then
  CURRENT_PATH=$(dirname "$0")
  . ${CURRENT_PATH}/build_local.sh
fi

python src/python_grpc/server.py &
GRPC_SERVER_PID=$!
./rest_reverse_proxy &
REST_PROXY_PID=$!
node src/ui/app.js &
NODE_UI_PID=$!

echo "Background processes started: $GRPC_SERVER_PID $REST_PROXY_PID $NODE_UI_PID"

# Kill background processes on script termination.
trap "kill -9 $GRPC_SERVER_PID $REST_PROXY_PID $NODE_UI_PID" INT TERM EXIT

# Timeout in 5 minutes.
sleep 300
