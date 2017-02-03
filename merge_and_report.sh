#!/bin/bash

source global.conf
source report_params.sh

if [ -z ${REPO_NAME+x} ] || [ -z ${REPO_URL+x} ] || [ -z ${REPORT_CREATION_DIR+x} ]; then
    echo "Please provide proper parameters in global.conf"
    exit 1;
fi

CHUNK_FILTER="BRANCH-.*-BUILD-[0-9]*-JOB-[0-9]*-OF-[0-9]*.zip"

function clean_previous {
    rm coverage.json
    find chunks -type f -name ${CHUNK_FILTER%.*} -delete;
}

function merge {
    OUT_REPORT_PATH=$1
    MERGE_CMD="$(pwd)/node_modules/.bin/istanbul-combine -d $OUT_REPORT_PATH -r lcov -r html "
    for CHUNK in $(find chunks -type d -name ${CHUNK_FILTER%.*}); do
        if [ ! -e ${CHUNK}/coverage.json ]; then
            echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] No report found at path ${CHUNK}/coverage.json. Skipping."  | \
                tee -a logs/.merge_and_report.log;
        else
            sed -i -- 's#'${REPORT_CREATION_DIR}'###g' ${CHUNK}/coverage.json
            MERGE_CMD+="$(pwd)/$CHUNK/coverage.json "
        fi
    done

    rm -rf ${OUT_REPORT_PATH}
    cd ${REPO_NAME}
    eval ${MERGE_CMD}
    cd ..

    if [ ! -e ${OUT_REPORT_PATH} ]; then
      echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Unable to merge chunked reports into ${OUT_REPORT_PATH} Failed on command: ${MERGE_CMD}"  | \
        tee -a logs/.merge_and_report.log;
      exit 1
    fi

    echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Successfully merged reports into ${OUT_REPORT_PATH} with command: ${MERGE_CMD}" | \
        tee -a logs/.merge_and_report.log;
}

function prepare_repo {
    REPO_NAME=$1
    BRANCH=$2
    cd ${REPO_NAME}
    git fetch
    git checkout ${BRANCH}
    cd ..

    echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] $REPO_NAME updated and switched on branch $BRANCH" | \
        tee -a logs/.merge_and_report.log;
}

function report {
    LCOV_REPORT_PATH=$1
    cat ${LCOV_REPORT_PATH} | node_modules/.bin/coveralls
    if [ $? == 0 ]; then
        echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Successfully sent report to coveralls!" | \
            tee -a logs/.merge_and_report.log;
    else
        echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Unable to merge chunked reports into ${OUT_REPORT_PATH}. Failed on command: ${MERGE_CMD}"  | \
            tee -a logs/.merge_and_report.log;
        exit 1
    fi
}

clean_previous

echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Merging all chunks into one report..." | \
    tee -a logs/.merge_and_report.log;

find chunks -type f -name ${CHUNK_FILTER} | while read CHUNK_ZIP; do
    echo $CHUNK_ZIP
    unzip ${CHUNK_ZIP} -d ${CHUNK_ZIP%.*} &&
    rm ${CHUNK_ZIP} &&
    echo "[LOG][$(date -u "+%Y-%m-%d %H:%M:%S") UTC] Chunk ${CHUNK_ZIP} unpacked" | \
        tee -a logs/.merge_and_report.log;
done

OUT_REPORT_PATH=$(pwd)/merged-coverage
BRANCH=eval get_branch `get_first_coverage`
prepare_repo ${REPO_NAME} get_branch
merge ${OUT_REPORT_PATH}
report ${OUT_REPORT_PATH}/lcov.info
