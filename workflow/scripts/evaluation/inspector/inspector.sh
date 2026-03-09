#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
ASSEMBLY_FASTA_HAP1=$2
ASSEMBLY_FASTA_HAP2=$3
FASTQ=$4
REFERENCE=$5
OUTPUT_DIR=$6
SEX=$7
THREADS=$8

rm -rf ${OUTPUT_DIR}/HP1 ${OUTPUT_DIR}/HP2 ${OUTPUT_DIR}/hp1 ${OUTPUT_DIR}/hp2
mkdir -p ${OUTPUT_DIR}/hp1
mkdir -p ${OUTPUT_DIR}/hp2

if [ ${SEX} = "female" ]; then
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${REFERENCE} > ${OUTPUT_DIR}/reference_noY.fa
    REFERENCE=${OUTPUT_DIR}/reference_noY.fa
fi

inspector.py \
    -c ${ASSEMBLY_FASTA_HAP1} \
    -r ${FASTQ} \
    --ref ${REFERENCE} \
    -o ${OUTPUT_DIR}/hp1 \
    -t ${THREADS} \
    --datatype hifi

inspector.py \
    -c ${ASSEMBLY_FASTA_HAP2} \
    -r ${FASTQ} \
    --ref ${REFERENCE} \
    -o ${OUTPUT_DIR}/hp2 \
    -t ${THREADS} \
    --datatype hifi

echo ${?}
