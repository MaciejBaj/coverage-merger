#!/bin/bash

source ./global.conf
source report_params.sh

function remove_old_reports {
    LATEST_BUILD=$1
    LATEST_BUILD_FILTER="BRANCH-*-BUILD-$LATEST_BUILD-JOB-[0-9]*-OF-[0-9]*.zip"
    find coverages -type f -not -name ${LATEST_BUILD_FILTER} | while read OLD_REPORT; do
        rm ${OLD_REPORT} && echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Removed the report for old build (${OLD_REPORT})" | \
            tee -a logs/.watch_coverages.log;
    done
}

function get_declared_test_number {
    eval get_jobs `get_first_coverage`
}

function clone_repo {
    REPO_NAME=$1
    REPO_URL=$2
    rm -rf ${REPO_NAME}
    git clone ${REPO_URL}
}

if [ -z ${REPO_NAME+x} ] || [ -z ${REPO_URL+x} ]; then
    echo "Please provide proper git repositories parameters in global.conf"
    exit 1;
fi

inotifywait -m ./coverages -e create -e moved_to |
    while read path action file; do
        echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] The file '$file' appeared in directory '$path' via '$action'" | \
            tee -a logs/.watch_coverages.log;

        LATEST_BUILD=`get_latest_build`
        remove_old_reports ${LATEST_BUILD}

        if (( `reports_count` == `get_declared_test_number ${LATEST_BUILD}` )); then
            rm -rf chunks/*
            mv coverages/* chunks
            echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] All chunks collected! Starting merging script.." | \
                    tee -a logs/.watch_coverages.log;
            bash merge_and_report.sh ${LATEST_BUILD}
        fi
    done
