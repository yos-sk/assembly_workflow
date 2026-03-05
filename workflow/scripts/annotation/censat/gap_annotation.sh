#!/bin/bash

INPUT_FASTA=$1
OUTPUT_DIR=$2

WORK_DIR=${OUTPUT_DIR}/work

mkdir -p ${WORK_DIR}/Gap
seqtk gap -l 2 ${INPUT_FASTA} > ${WORK_DIR}/Gap/gaps.bed
cat ${WORK_DIR}/Gap/gaps.bed | awk 'BEGIN{OFS="\t"} {print $1, $2, $3, "GAP", "0", ".", $2, $3, "0,0,0"}' > ${OUTPUT_DIR}/gaps.filtered.bed

echo ${?}
