#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
ASSEMBLER=$2
hap1_fasta=$3
hap2_fasta=$4
FASTQ=$5
OUTPUT_DIR=$6
PLATFORM=$7 # hifi or ont
THREADS=$8

mkdir -p ${OUTPUT_DIR}

cat ${hap1_fasta} ${hap2_fasta} > ${OUTPUT_DIR}/reference.fa

if [ $PLATFORM == "hifi" ]; then
    prefix="map-hifi"
else
    prefix="map-ont"
fi

minimap2 -t ${THREADS} --cs -L -ax ${prefix} -I 8G ${OUTPUT_DIR}/reference.fa ${FASTQ} | samtools view -Sbh > ${OUTPUT_DIR}/tmp_${PLATFORM}.unsorted
samtools sort -@ ${THREADS} ${OUTPUT_DIR}/tmp_${PLATFORM}.unsorted -o ${OUTPUT_DIR}/${SAMPLE}_${PLATFORM}.bam
rm ${OUTPUT_DIR}/tmp_${PLATFORM}.unsorted
samtools index -@ ${THREADS} ${OUTPUT_DIR}/${SAMPLE}_${PLATFORM}.bam

rm ${OUTPUT_DIR}/reference.fa

echo ${?}
