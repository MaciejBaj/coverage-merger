#!/bin/bash

PROJECT_CONF=$1
RESET=$2

source ${PROJECT_CONF}
source report_params.sh

function remove_old_reports {
    pwd
    LATEST_BUILD=$1
    LATEST_BUILD_FILTER="BRANCH-*-BUILD-$LATEST_BUILD-JOB-[0-9]*-OF-[0-9]*.zip"
    find coverages -type f -not -name ${LATEST_BUILD_FILTER} | while read OLD_REPORT; do
        rm ${OLD_REPORT} && echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Removed the report for old build (${OLD_REPORT})" | \
            tee -a logs/.watch_coverages.log
    done
}

function get_declared_test_number {
    eval get_jobs `get_first_coverage`
}

function clone_repo {
    REPO_NAME=$1
    REPO_URL=$2
    cd ${REPO_NAME}
    rm -rf ${REPO_NAME}
    git clone ${REPO_URL}
    cd ..
}

function reset_project_dir {
    REPO_NAME=$1
    rm -rf ${REPO_NAME}
    mkdir -p ${REPO_NAME}
    mkdir ${REPO_NAME}/coverages
    mkdir ${REPO_NAME}/chunks
    mkdir ${REPO_NAME}/logs
    echo "RESET"
}

if [ -z ${REPO_NAME+x} ] || [ -z ${REPO_URL+x} ]; then
    echo "Please provide proper conf file."
    exit 1
fi

mkdir -p ${REPO_NAME}

if [ ! -z ${RESET=x} ] || [ ! -e ${REPO_NAME}/${REPO_NAME} ]; then
    echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Resetting ${REPO_NAME} directory" | \
        tee -a ${REPO_NAME}/logs/.watch_coverages.log
    reset_project_dir ${REPO_NAME}
    clone_repo ${REPO_NAME} ${REPO_URL}
fi

MERGER_DIR=$(pwd)

inotifywait -m ${REPO_NAME}/coverages -e create -e moved_to |
    while read path action file; do
        source $1
        #Important: from this point we are in project directory
        cd ${MERGER_DIR}/${REPO_NAME}
        echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] The file '$file' appeared in directory '$path' via '$action'" | \
            tee -a logs/.watch_coverages.log
        if [[ ! ${file} =~ BRANCH-.*-BUILD-[0-9]*-JOB-[0-9]*-OF-[0-9]*.zip ]]; then
            rm coverages/${file}
        elif (( `reports_count` == `get_declared_test_number ${LATEST_BUILD}` )); then
            rm -rf chunks/*
            mv coverages/* chunks
            echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] All chunks collected! Starting merging script.." | \
                    tee -a logs/.watch_coverages.log
            cd ${MERGER_DIR}
            bash merge_and_report.sh ${PROJECT_CONF} ${LATEST_BUILD}
        fi
        cd ${MERGER_DIR}
    done
