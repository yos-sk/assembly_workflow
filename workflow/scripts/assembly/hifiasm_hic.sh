#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
ONT=$2
HIFI=$3
HIC_READ1=$4
HIC_READ2=$5
OUTPUT_DIR=$6
THREADS=$7

WORK_DIR=${OUTPUT_DIR}/workspace

mkdir -p ${WORK_DIR}

hifiasm \
    -o ${WORK_DIR}/${SAMPLE} \
    -t ${THREADS} \
    --ul ${ONT} \
    --h1 ${HIC_READ1} \
    --h2 ${HIC_READ2} \
    ${HIFI}
    
awk '/^S/{print ">"$2;print $3}' ${WORK_DIR}/${SAMPLE}.hic.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.fa
awk '/^S/{print ">"$2;print $3}' ${WORK_DIR}/${SAMPLE}.hic.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${WORK_DIR}/${SAMPLE}.hic.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa

echo ${?}

