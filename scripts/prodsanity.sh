#!/bin/sh

set -e

echo "Testing space_api_proto.Tle/Decode"
echo
echo "gRPC"
grpcurl \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}' \
  api.thiago.pub:9090 \
  space_api_proto.Tle/Decode

echo
echo "REST"
curl -X POST api.thiago.pub/space/v1/tle/decode \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}'


echo "Testing space_api_proto.Tle/ToOrbit"
echo
echo "gRPC"
grpcurl \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}' \
  api.thiago.pub:9090 \
  space_api_proto.Tle/ToOrbit

echo
echo "REST"
curl -X POST api.thiago.pub/space/v1/tle/orbit \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}'
