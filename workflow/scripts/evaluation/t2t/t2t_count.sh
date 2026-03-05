#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

ASSEMBLY_FASTA_HAP1=$1
ASSEMBLY_FASTA_HAP2=$2
REFERENCE=$3
OUTPUT_DIR=$4
SEX=$5

mkdir -p ${OUTPUT_DIR}

if [ ${SEX} = "female" ]; then
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${REFERENCE} > ${OUTPUT_DIR}/reference_noY.fa
    REFERENCE=${OUTPUT_DIR}/reference_noY.fa
fi

seqtk telo ${ASSEMBLY_FASTA_HAP1} > ${OUTPUT_DIR}/telo_hap1.tsv
seqtk telo ${ASSEMBLY_FASTA_HAP2} > ${OUTPUT_DIR}/telo_hap2.tsv

mashmap \
    -f one-to-one \
    --pi 99 \
    --segLength 100000 \
    --dense \
    -r ${REFERENCE} \
    -q ${ASSEMBLY_FASTA_HAP1} \
    --output ${OUTPUT_DIR}/APPROX-ALIGN_hap1.paf

mashmap \
    -f one-to-one \
    --pi 99 \
    --segLength 100000 \
    --dense \
    -r ${REFERENCE} \
    -q ${ASSEMBLY_FASTA_HAP2} \
    --output ${OUTPUT_DIR}/APPROX-ALIGN_hap2.paf

if [ ${SEX} = "female" ]; then
    rm ${OUTPUT_DIR}/reference_noY.fa
fi

echo ${?}
