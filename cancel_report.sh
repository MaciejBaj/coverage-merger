#!/bin/bash

TRAVIS_BUILD_NUMBER=$1

if [ -z ${TRAVIS_BUILD_NUMBER} ]; then
  echo "[ERR][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Invoked without TRAVIS_BUILD_NUMBER parameter. Exit now." | \
    tee -a logs/.cancel_report.log;
  exit 1;
fi

echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Searching reports for build: ${TRAVIS_BUILD_NUMBER}" | \
    tee -a logs/.cancel_report.log;
BUILD_FILTER="BRANCH-.*-BUILD-${TRAVIS_BUILD_NUMBER}-JOB-[0-9]*-OF-[0-9]*.zip"

find coverages -type f -name ${BUILD_FILTER} | while read REPORT; do
    rm ${REPORT} && echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Removed the report for build ${TRAVIS_BUILD_NUMBER}: (${REPORT})" | \
        tee -a logs/.cancel_report.log;
done

#BUILD-0-JOB-0-OF-0.zip
#chunks/BUILD-139-JOB-2-OF-14/lcov.info