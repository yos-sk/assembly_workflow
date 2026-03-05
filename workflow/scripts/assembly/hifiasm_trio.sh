#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
ONT=$2
HIFI=$3
PAT_R1=$4
PAT_R2=$5
MAT_R1=$6
MAT_R2=$7
OUTPUT_DIR=$8

WORK_DIR=${OUTPUT_DIR}/workspace

mkdir -p ${WORK_DIR}


yak count -b37 -t16 -o ${WORK_DIR}/pat.yak <(cat ${PAT_R1} ${PAT_R2}) <(cat ${PAT_R1} ${PAT_R2})
yak count -b37 -t16 -o ${WORK_DIR}/mat.yak <(cat ${MAT_R1} ${MAT_R2}) <(cat ${MAT_R1} ${MAT_R2})

hifiasm \
    -o ${WORK_DIR}/${SAMPLE} \
    -t 56 \
    --ul ${ONT} \
    -1 ${WORK_DIR}/pat.yak \
    -2 ${WORK_DIR}/mat.yak \
    ${HIFI}

awk '/^S/{print ">"$2;print $3}' ${WORK_DIR}/${SAMPLE}.dip.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.fa
awk '/^S/{print ">"$2;print $3}' ${WORK_DIR}/${SAMPLE}.dip.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${WORK_DIR}/${SAMPLE}.dip.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa

echo ${?}

