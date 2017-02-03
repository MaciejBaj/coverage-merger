#!/bin/bash

BUILD_FILTER="BRANCH-*-BUILD-[0-9]*-JOB-[0-9]*-OF-[0-9]*.zip"

function find_reports {
    echo `find coverages -type f -name ${BUILD_FILTER}`
}

function reports_count {
    echo `find coverages -type f -name ${BUILD_FILTER} | wc -l`
}

function get_latest_build {
   LATEST_BUILD=0
   REPORTS=`find_reports`
   for REPORT in "${REPORTS[@]}"; do
    BUILD=`get_build ${REPORT}`
    if (( BUILD > LATEST_BUILD )); then
      LATEST_BUILD=${BUILD}
    fi
    done
    echo "$LATEST_BUILD"
}

function get_first_coverage {
    echo coverages/`ls coverages | head -n 1`
}

function get_report_param {
    FILE=$1
    PARAM=$2
    echo `echo ${FILE} | sed -E 's/.*BRANCH-(.*)-BUILD-([0-9]*)-JOB-([0-9]*)-OF-([0-9]*).zip/\'${PARAM}'/g'`
}

function get_branch {
    echo `get_report_param $1 1`
}

function get_build {
    echo `get_report_param $1 2`
}

function get_job {
   echo `get_report_param $1 3`
}

function get_jobs {
   echo `get_report_param $1 4`
}

