#!/bin/bash

set -eux -o pipefail

INPUT_FILE=$1
OUTPUT_DIR=$2
SAMPLE=$3

mkdir -p ${OUTPUT_DIR}
python3 /opt/RM2Bed.py \
    ${INPUT_FILE} \
    --out_dir ${OUTPUT_DIR} \
    --out_prefix ${SAMPLE} \
    --ovlp_resolution 'higher_score'

sort -k 1,1 -k 2,2n ${OUTPUT_DIR}/${SAMPLE}_rm.bed > ${OUTPUT_DIR}/rmsk_tmp.bed && mv ${OUTPUT_DIR}/rmsk_tmp.bed ${OUTPUT_DIR}/${SAMPLE}_rm.bed

echo ${?}
