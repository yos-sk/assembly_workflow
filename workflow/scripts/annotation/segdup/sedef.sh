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

# --------------------------------------------------------------------
# Exclude chrY contigs before sedef. assembly_filter always renames contigs to
# PanSN ({sample}#{hap}#{chrom}), so the ref.table chrY assignment is encoded in
# the name as "#chrY" (or "#chrY_ctgN"). Drop those and run sedef on the rest.
# Female samples have no chrY (the filter drops it from the reference), so the
# keep-list is unchanged and this is a no-op.
# --------------------------------------------------------------------
awk -F'\t' '$1 !~ /#chrY(_ctg[0-9]+)?$/ {print $1}' ${ASSEMBLY_HAP1}.fai > ${WORK_DIR}/keep_hap1.txt
echo "[sedef] hap1: keep $(wc -l < ${WORK_DIR}/keep_hap1.txt) / $(wc -l < ${ASSEMBLY_HAP1}.fai) contigs (chrY excluded)"
seqtk subseq ${ASSEMBLY_HAP1} ${WORK_DIR}/keep_hap1.txt > ${WORK_DIR}/hap1.noY.fa
samtools faidx ${WORK_DIR}/hap1.noY.fa
ASSEMBLY_HAP1=${WORK_DIR}/hap1.noY.fa

awk -F'\t' '$1 !~ /#chrY(_ctg[0-9]+)?$/ {print $1}' ${ASSEMBLY_HAP2}.fai > ${WORK_DIR}/keep_hap2.txt
echo "[sedef] hap2: keep $(wc -l < ${WORK_DIR}/keep_hap2.txt) / $(wc -l < ${ASSEMBLY_HAP2}.fai) contigs (chrY excluded)"
seqtk subseq ${ASSEMBLY_HAP2} ${WORK_DIR}/keep_hap2.txt > ${WORK_DIR}/hap2.noY.fa
samtools faidx ${WORK_DIR}/hap2.noY.fa
ASSEMBLY_HAP2=${WORK_DIR}/hap2.noY.fa

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
