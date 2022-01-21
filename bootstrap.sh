#!/bin/sh

set -e

echo "starting gRPC server"
python3 src/python_grpc/server.py &

echo "starting REST API"
./rest_reverse_proxy &

echo "starting Node UI"
node src/ui/app.js
