#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

ASSEMBLY_HAP1=$1
ASSEMBLY_HAP2=$2
REPEAT_MASKER=$3
TRF=$4
WORK_DIR=$5
OUTPUT_DIR=$6

mkdir -p ${WORK_DIR}
mkdir -p ${OUTPUT_DIR}

cut -f 1,1 ${ASSEMBLY_HAP1}.fai > ${WORK_DIR}/grep_file_hap1.txt
cut -f 1,1 ${ASSEMBLY_HAP2}.fai > ${WORK_DIR}/grep_file_hap2.txt

zgrep -f ${WORK_DIR}/grep_file_hap1.txt ${REPEAT_MASKER} > ${WORK_DIR}/rmsk_hap1.bed
zgrep -f ${WORK_DIR}/grep_file_hap2.txt ${REPEAT_MASKER} > ${WORK_DIR}/rmsk_hap2.bed

grep Alpha ${WORK_DIR}/rmsk_hap1.bed | bedtools merge -d 35 -i - > ${WORK_DIR}/mask_region_hap1.bed
grep HSAT ${WORK_DIR}/rmsk_hap1.bed | bedtools merge -d 75 -i - >> ${WORK_DIR}/mask_region_hap1.bed

grep Alpha ${WORK_DIR}/rmsk_hap2.bed | bedtools merge -d 35 -i - > ${WORK_DIR}/mask_region_hap2.bed
grep HSAT ${WORK_DIR}/rmsk_hap2.bed | bedtools merge -d 75 -i - >> ${WORK_DIR}/mask_region_hap2.bed

# merge large simple_repeats
grep Simple_repeat ${WORK_DIR}/rmsk_hap1.bed | \
    awk '$3-$2 > 1000 {{print $0}}' | \
    bedtools merge -d 100 -i - | \
    bedtools slop -b 100 -g ${ASSEMBLY_HAP1}.fai -i - >> ${WORK_DIR}/mask_region_hap1.bed

grep Simple_repeat ${WORK_DIR}/rmsk_hap2.bed | \
    awk '$3-$2 > 1000 {{print $0}}' | \
    bedtools merge -d 100 -i - | \
    bedtools slop -b 100 -g ${ASSEMBLY_HAP2}.fai -i - >> ${WORK_DIR}/mask_region_hap2.bed

grep -f ${WORK_DIR}/grep_file_hap1.txt ${TRF} > ${WORK_DIR}/trf_hap1.bed
grep -f ${WORK_DIR}/grep_file_hap2.txt ${TRF} > ${WORK_DIR}/trf_hap2.bed

cat ${WORK_DIR}/trf_hap1.bed ${WORK_DIR}/rmsk_hap1.bed | cut -f 1-3 >> ${WORK_DIR}/mask_region_hap1.bed
cat ${WORK_DIR}/trf_hap2.bed ${WORK_DIR}/rmsk_hap2.bed | cut -f 1-3 >> ${WORK_DIR}/mask_region_hap2.bed

cut -f 1-3 ${WORK_DIR}/mask_region_hap1.bed | bedtools sort -i - | bedtools merge -i - | \
    awk '$3-$2 > 2000 {{print $0}}' | \
    bedtools merge -d 100 -i - > ${WORK_DIR}/mask_region_merge_hap1.bed

cut -f 1-3 ${WORK_DIR}/mask_region_hap2.bed | bedtools sort -i - | bedtools merge -i - | \
    awk '$3-$2 > 2000 {{print $0}}' | \
    bedtools merge -d 100 -i - > ${WORK_DIR}/mask_region_merge_hap2.bed

cut -f 1-3 ${WORK_DIR}/mask_region_hap1.bed ${WORK_DIR}/mask_region_merge_hap1.bed | bedtools sort -i - | bedtools merge -i - | \
    seqtk seq -l 50 -M /dev/stdin ${ASSEMBLY_HAP1} > ${WORK_DIR}/hap1.masked.fa
samtools faidx ${WORK_DIR}/hap1.masked.fa

cut -f 1-3 ${WORK_DIR}/mask_region_hap2.bed ${WORK_DIR}/mask_region_merge_hap2.bed | bedtools sort -i - | bedtools merge -i - | \
    seqtk seq -l 50 -M /dev/stdin ${ASSEMBLY_HAP2} > ${WORK_DIR}/hap2.masked.fa
samtools faidx ${WORK_DIR}/hap2.masked.fa

/tools/sedef/sedef.sh \
    -o ${OUTPUT_DIR}/HP1/ \
    -j 14 \
    -f \
    ${WORK_DIR}/hap1.masked.fa


/tools/sedef/sedef.sh \
    -o ${OUTPUT_DIR}/HP2/ \
    -j 14 \
    -f \
    ${WORK_DIR}/hap2.masked.fa 

echo ${?}
