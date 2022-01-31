#!/bin/sh

set -e

echo "starting gRPC server"
python3 src/python_grpc/server.py | tee ${CODE_ROOT}/logs/grpc_server.log &

echo "starting REST API"
./rest_reverse_proxy | tee ${CODE_ROOT}/logs/rest_proxy.log &

echo "starting Node UI"
node src/ui/app.js | tee ${CODE_ROOT}/logs/node_ui.log
