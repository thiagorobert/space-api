#!/bin/sh

set -e

CLEAN="${1:-noclean}"

if [ ${CLEAN} != "noclean" ]; then
  CURRENT_PATH=$(dirname "$0")
  . ${CURRENT_PATH}/build_local.sh
fi

python src/python_grpc/server.py &
./rest_reverse_proxy &
node src/ui/app.js &

# Kill background processes.
trap 'trap - TERM && kill -- -$$' INT TERM EXIT
