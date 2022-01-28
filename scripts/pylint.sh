#!/bin/sh

set -e

pylint --disable=C0114,C0115,C0116,C0103,E0401,E0611,W0613,R0201,E1101 src/python_grpc/
