#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

INPUT_BAM=$1
OUTPUT_DIR=$2
WORK_DIR=$3
THREADS=$4

OUTFILE=${OUTPUT_DIR}/nucflag_output.txt
PLOTDIR=${OUTPUT_DIR}/plot
COVDIR=${OUTPUT_DIR}/cov
OUTPUT_BAM=${WORK_DIR}/input.bam

mkdir -p ${WORK_DIR}

samtools view -F 2308 -@ ${THREADS} -Shb ${INPUT_BAM} > ${OUTPUT_BAM}
samtools index -@ ${THREADS} ${OUTPUT_BAM}

nucflag \
    -i ${OUTPUT_BAM} \
    -d ${PLOTDIR} \
    --output_cov_dir ${COVDIR} \
    -s ${OUTFILE} \
    -t ${THREADS} \
> ${OUTPUT_DIR}/nucflag_misassembly.txt

rm ${OUTPUT_BAM}*

echo ${?}
