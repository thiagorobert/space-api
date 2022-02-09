#!/bin/sh

set -e

while true; do
  SOCRATES_LATEST=${CODE_ROOT}/celestrak/socrates-`date +"%Y%m%d%H%M%S"`.txt
  curl -s https://celestrak.com/SOCRATES/sort-timein.txt -o ${SOCRATES_LATEST}
  ln -s ${SOCRATES_LATEST} ${CODE_ROOT}/celestrak/socrates-latest.txt
  STATIONS_LATEST=${CODE_ROOT}/celestrak/stations-`date +"%Y%m%d%H%M%S"`.txt
  curl -s https://celestrak.com/NORAD/elements/stations.txt -o ${STATIONS_LATEST}
  ln -s ${STATIONS_LATEST} ${CODE_ROOT}/celestrak/stations-latest.txt

  sleep 86400
done
