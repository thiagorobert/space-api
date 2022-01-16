#!/bin/sh

set -e

echo "starting gRPC server"
python3 src/python_grpc/server.py &

echo "starting REST API"
./rest_reverse_proxy
