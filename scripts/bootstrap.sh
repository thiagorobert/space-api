#!/bin/sh

set -e

echo "starting gRPC server"
python3 ${CODE_ROOT}/src/python_grpc/server.py 2>&1 | tee ${CODE_ROOT}/logs/grpc_server.log &

echo "starting REST API"
${CODE_ROOT}/rest_reverse_proxy | tee ${CODE_ROOT}/logs/rest_proxy.log &

echo "starting script to copy content from Celestrak"
${CODE_ROOT}/scripts/copy-from-celestrak.sh &

echo "starting file server"
cd ${CODE_ROOT}/celestrak/
python3 -m http.server 9092 2>&1 | tee ${CODE_ROOT}/logs/file_server.log &
cd -

echo "starting Node UI"
node ${CODE_ROOT}/src/ui/app.js | tee ${CODE_ROOT}/logs/node_ui.log
