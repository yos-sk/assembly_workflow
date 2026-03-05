#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

export BLASTDB_LMDB_MAP_SIZE=100000000

SAMPLE=$1
ASSEMBLY_FASTA=$2
OUTPUT_DIR=$3
SCRIPTS_DIR=$4
THREADS=$5

mkdir -p ${OUTPUT_DIR}
RepeatMasker \
    -species human \
    -e rmblast \
    -pa ${THREADS} \
    ${ASSEMBLY_FASTA} \
    -dir ${OUTPUT_DIR}

awk '{if (NR > 3) print $5 "\t" $6 - 1 "\t" $7 "\t" $10 "\t" $11}' ${OUTPUT_DIR}/${SAMPLE}.filt.fa.out | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.rmsk.bed
bgzip -f ${OUTPUT_DIR}/${SAMPLE}.rmsk.bed
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.rmsk.bed.gz

awk '{if ($11 == "Simple_repeat") print $5 "\t" $6 - 1 "\t" $7}' ${OUTPUT_DIR}/${SAMPLE}.filt.fa.out | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.simple_repeats.bed
bgzip -f ${OUTPUT_DIR}/${SAMPLE}.simple_repeats.bed
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.simple_repeats.bed.gz

python3 ${SCRIPTS_DIR}/annotation/RepeatMasker/proc_rmsk.py ${OUTPUT_DIR}/${SAMPLE}.filt.fa.out | sort -k 1,1 -k 2,2n | bgzip -f -c > ${OUTPUT_DIR}/${SAMPLE}.LINE1.bed.gz
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.LINE1.bed.gz

echo ${?}
