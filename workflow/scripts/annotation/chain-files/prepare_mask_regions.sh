#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

CHM13_SATELLITE=$1
CHM13=$2
GRCH38_CEN=$3
GRCH38_EXCLUDE=$4
GRCH38=$5
OUTPUT_DIR=$6
WORK_DIR=$7
SCRIPTS_DIR=$8

mkdir -p ${OUTPUT_DIR}
mkdir -p ${WORK_DIR}

# chm13
if [ ! -e ${OUTPUT_DIR}/chm13.masked_noY.fa ] || [ ! -s ${OUTPUT_DIR}/chm13.masked_noY.fa ]; then
    grep -e hor -e mon -e hsat  ${CHM13_SATELLITE} | \
        awk '{if (NR != 1) print $1 "\t"  $2 "\t" $3}' > ${WORK_DIR}/chm13_mask_regions.bed

    bedtools maskfasta \
        -fi ${CHM13} \
        -fo ${OUTPUT_DIR}/chm13.masked.fa \
        -bed ${WORK_DIR}/chm13_mask_regions.bed
    samtools faidx ${OUTPUT_DIR}/chm13.masked.fa
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${OUTPUT_DIR}/chm13.masked.fa > ${OUTPUT_DIR}/chm13.masked_noY.fa
    samtools faidx ${OUTPUT_DIR}/chm13.masked_noY.fa
fi

# GRCh38
if [ ! -e ${OUTPUT_DIR}/GRCh38.masked_noY.fa ] || [ ! -s ${OUTPUT_DIR}/GRCh38.masked_noY.fa ]; then
    zcat ${GRCH38_CEN} | \
        awk '{print $2 "\t"  $3 - 1 "\t" $4}' > ${WORK_DIR}/GRCh38_mask_regions.bed
    cat ${GRCH38_EXCLUDE} >> ${WORK_DIR}/GRCh38_mask_regions.bed

    python3 ${SCRIPTS_DIR}/chain-files/remove_unlocalized_GRCh38.py ${GRCH38} > ${WORK_DIR}/GRCh38_removed_unlocalized.fa
    bedtools maskfasta \
        -fi ${WORK_DIR}/GRCh38_removed_unlocalized.fa \
        -fo ${OUTPUT_DIR}/GRCh38.masked.fa \
        -bed ${WORK_DIR}/GRCh38_mask_regions.bed
    samtools faidx ${OUTPUT_DIR}/GRCh38.masked.fa
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${OUTPUT_DIR}/GRCh38.masked.fa > ${OUTPUT_DIR}/GRCh38.masked_noY.fa
    samtools faidx ${OUTPUT_DIR}/GRCh38.masked_noY.fa
fi

echo ${?}
