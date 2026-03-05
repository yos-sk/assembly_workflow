#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

FLAGGER_HiFi=$1
FLAGGER_ONT=$2
NUCFLAG=$3
INSPECTOR_SMALL_HP1=$4
INSPECTOR_SMALL_HP2=$5
INSPECTOR_STRUCTURAL_HP1=$6
INSPECTOR_STRUCTURAL_HP2=$7
OUTPUT_DIR=$8
WORK_DIR=$9
SCRIPTS_DIR=${10}

mkdir -p ${WORK_DIR}
mkdir -p ${OUTPUT_DIR}

awk '{if (NR != 1 && $4 != "Hap") print}' ${FLAGGER_HiFi} > ${WORK_DIR}/flagger_hifi_error.bed
awk '{if (NR != 1 && $4 != "Hap") print}' ${FLAGGER_ONT} > ${WORK_DIR}/flagger_ont_error.bed

python3 ${SCRIPTS_DIR}/merge_inspector_results.py \
    ${INSPECTOR_SMALL_HP1} \
    ${INSPECTOR_SMALL_HP2} \
    ${INSPECTOR_STRUCTURAL_HP1} \
    ${INSPECTOR_STRUCTURAL_HP2} \
    ${WORK_DIR}/inspector_error.bed

sort -k 1,1 -k 2,2n ${WORK_DIR}/inspector_error.bed > ${WORK_DIR}/inspector_error.sorted.bed

bedtools multiinter \
    -i ${WORK_DIR}/flagger_hifi_error.bed \
       ${WORK_DIR}/flagger_ont_error.bed \
       ${NUCFLAG} \
       ${WORK_DIR}/inspector_error.sorted.bed \
> ${WORK_DIR}/misassembly_intersect.bed

awk '$1 ~ /haplotype1|h1tg|pat/ {if ($4 > 1) print}' ${WORK_DIR}/misassembly_intersect.bed | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/misassembly.intersect.hap1.bed
awk '$1 ~ /haplotype2|h2tg|mat/ {if ($4 > 1) print}' ${WORK_DIR}/misassembly_intersect.bed | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/misassembly.intersect.hap2.bed

bgzip -f ${OUTPUT_DIR}/misassembly.intersect.hap1.bed
tabix -p bed ${OUTPUT_DIR}/misassembly.intersect.hap1.bed.gz
bgzip -f ${OUTPUT_DIR}/misassembly.intersect.hap2.bed
tabix -p bed ${OUTPUT_DIR}/misassembly.intersect.hap2.bed.gz

echo ${?}
