#!/bin/bash

set -eux -o pipefail

INPUT_FASTA=$1
OUTPUT_DIR=$2
WORK_DIR=${OUTPUT_DIR}/work

mkdir -p ${WORK_DIR}/split
awk -v workdir=${WORK_DIR} '/^>/ { file=workdir"/split/" substr($1,2) ".fa" } { print > file }' ${INPUT_FASTA}

echo ${?}
