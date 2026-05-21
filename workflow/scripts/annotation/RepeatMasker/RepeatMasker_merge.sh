#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
HAP1_OUT=$2
HAP2_OUT=$3
OUTPUT_DIR=$4
SCRIPTS_DIR=$5

MERGED_OUT=${OUTPUT_DIR}/${SAMPLE}.filt.fa.out

# Merge .out files (keep header from hap1, append data from hap2)
head -3 ${HAP1_OUT} > ${MERGED_OUT}
tail -n +4 ${HAP1_OUT} >> ${MERGED_OUT}
tail -n +4 ${HAP2_OUT} >> ${MERGED_OUT}

# Create rmsk.bed.gz
awk '{if (NR > 3) print $5 "\t" $6 - 1 "\t" $7 "\t" $10 "\t" $11}' ${MERGED_OUT} | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.rmsk.bed
bgzip -f ${OUTPUT_DIR}/${SAMPLE}.rmsk.bed
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.rmsk.bed.gz

# Create simple_repeats.bed.gz
awk '{if ($11 == "Simple_repeat") print $5 "\t" $6 - 1 "\t" $7}' ${MERGED_OUT} | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.simple_repeats.bed
bgzip -f ${OUTPUT_DIR}/${SAMPLE}.simple_repeats.bed
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.simple_repeats.bed.gz

# Create LINE1.bed.gz
python3 ${SCRIPTS_DIR}/annotation/RepeatMasker/proc_rmsk.py ${MERGED_OUT} | sort -k 1,1 -k 2,2n | bgzip -f -c > ${OUTPUT_DIR}/${SAMPLE}.LINE1.bed.gz
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.LINE1.bed.gz

echo ${?}
