#!/bin/bash

TRAVIS_BUILD_NUMBER=$1

if [ -z ${TRAVIS_BUILD_NUMBER} ]; then
  echo "[ERR][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Invoked without TRAVIS_BUILD_NUMBER parameter. Exit now." | tee -a logs/.cancel-report.log;
  exit 1;
fi

echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Searching reports for build: ${TRAVIS_BUILD_NUMBER}" | tee -a logs/.cancel-report.log;
BUILD_FILTER="BUILD-${TRAVIS_BUILD_NUMBER}-JOB-[0-9]*-OF-[0-9]*.*"

find coverages -type f -name ${BUILD_FILTER} -delete | while read REPORT; do
    rm ${REPORT} || echo "[ERR][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Failed to remove file ${REPORT}. Exit now." | tee -a logs/.cancel-report.log && exit 1;
    echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Removed the report for build: ${TRAVIS_BUILD_NUMBER}: (${REPORT})" | tee -a logs/.cancel-report.log;
done
