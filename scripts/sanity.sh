#!/bin/sh

set -e

HOSTNAME="${1:-localhost}"
GRPCURL_PLAINTEXT="--plaintext"
if [[ ${HOSTNAME} != "localhost" ]]; then
  GRPCURL_PLAINTEXT=""
fi
REST_ENDPOINT=${HOSTNAME}:8081
if [[ ${HOSTNAME} != "localhost" ]]; then
  REST_ENDPOINT=https://${HOSTNAME}
fi

echo "+++++++ Testing hostname ${HOSTNAME} +++++++"


echo "==== Testing space_api_proto.Tle/Decode ===="
echo
echo "*********** gRPC"
grpcurl \
  ${GRPCURL_PLAINTEXT} \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}' \
  ${HOSTNAME}:9090 \
  space_api_proto.Tle/Decode

echo
echo "*********** REST"
curl -s -X POST ${REST_ENDPOINT}/space/v1/tle/decode \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}'


echo "==== Testing space_api_proto.Tle/ToOrbit ===="
echo
echo "*********** gRPC"
grpcurl \
  ${GRPCURL_PLAINTEXT} \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}' \
  ${HOSTNAME}:9090 \
  space_api_proto.Tle/ToOrbit

echo
echo "*********** REST"
curl -s -X POST ${REST_ENDPOINT}/space/v1/tle/orbit \
  -d '{"tle_data": {"name": "ISS (ZARYA)", "line1": "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996", "line2": "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"}}'


echo "==== Testing UI ===="
echo
echo "*********** Landing page"
curl -s -X GET ${HOSTNAME}:8080

echo
echo "*********** Landing page post"
curl -s -X POST ${HOSTNAME}:8080/submit \
  -d '-----------------------------23605125921461961015802936950
Content-Disposition: form-data; name="tle"

ISS (ZARYA)
1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996
2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05
-----------------------------23605125921461961015802936950--'
