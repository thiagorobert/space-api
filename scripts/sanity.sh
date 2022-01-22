#!/bin/sh

set -e

echo "Testing space_api_proto.Tle/Decode"
echo
echo "gRPC"
grpcurl \
  --plaintext \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}' \
  localhost:9090 \
  space_api_proto.Tle/Decode

echo
echo "REST"
curl -X POST localhost:8081/space/v1/tle/decode \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}'


echo "Testing space_api_proto.Tle/ToOrbit"
echo
echo "gRPC"
grpcurl \
  --plaintext \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}' \
  localhost:9090 \
  space_api_proto.Tle/ToOrbit

echo
echo "REST"
curl -X POST localhost:8081/space/v1/tle/orbit \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}'


echo "Testing UI"
echo
curl -X GET localhost:8080
