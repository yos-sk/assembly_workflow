#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# Arguments
HAP1_INPUT=$1
HAP2_INPUT=$2
REFERENCE=$3
SAMPLE=$4
SEX=$5
OUTPUT_DIR=$6
THREADS=$7
HAP1_OUTPUT=$8
HAP2_OUTPUT=$9
COMBINED_OUTPUT=${10}
HAP1_STATS=${11}
HAP2_STATS=${12}
SCRIPTS_DIR=${13}
WORK_DIR=${14}

DNA_NN_MODEL="/opt/dna-nn-0.1/models/attcc-alpha.knm"

mkdir -p ${WORK_DIR}
mkdir -p ${OUTPUT_DIR}

REFERENCE_FASTA=${REFERENCE}
if [ ${SEX} = "female" ]; then
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${REFERENCE} > ${WORK_DIR}/reference_noY.fa
    REFERENCE_FASTA=${WORK_DIR}/reference_noY.fa
fi

python3 ${SCRIPTS_DIR}/assembly/filter/filter_length_assembly.py \
    ${HAP1_INPUT} \
    ${HAP2_INPUT} \
    ${WORK_DIR}/${SAMPLE}.hap1.filt.fa \
    ${WORK_DIR}/${SAMPLE}.hap2.filt.fa

for hap in hap1 hap2; do
    if [ $hap = "hap1" ]; then
        INPUT_FASTA=${WORK_DIR}/${SAMPLE}.hap1.filt.fa
    else
        INPUT_FASTA=${WORK_DIR}/${SAMPLE}.hap2.filt.fa
    fi

    dna-brnn \
        -Ai ${DNA_NN_MODEL} \
        -t${THREADS} ${INPUT_FASTA} \
    | sort -k 1,1 -k 2,2n > ${WORK_DIR}/${SAMPLE}.${hap}_dna-brnn.bed
    bgzip -f ${WORK_DIR}/${SAMPLE}.${hap}_dna-brnn.bed
    tabix -p bed ${WORK_DIR}/${SAMPLE}.${hap}_dna-brnn.bed.gz

    bedtools maskfasta \
        -fi ${INPUT_FASTA} \
        -bed ${WORK_DIR}/${SAMPLE}.${hap}_dna-brnn.bed.gz \
        -fo ${WORK_DIR}/${SAMPLE}.${hap}.masked.fa

    minimap2 \
        -cx asm5 -t ${THREADS} \
        ${WORK_DIR}/${SAMPLE}.${hap}.masked.fa \
        ${REFERENCE_FASTA} \
    > ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.paf
    grep -v 'tp:A:S' ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.paf > ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.rmsec.paf

    python3 ${SCRIPTS_DIR}/assembly/filter/make_reference_table.py \
        -i ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.rmsec.paf \
    > ${OUTPUT_DIR}/${SAMPLE}.${hap}.ref.table

    python3 ${SCRIPTS_DIR}/assembly/filter/reverse_complement_ref.py \
        -r ${OUTPUT_DIR}/${SAMPLE}.${hap}.ref.table \
        -f ${INPUT_FASTA} \
    > ${OUTPUT_DIR}/${SAMPLE}.${hap}.filt.fa

    samtools faidx ${OUTPUT_DIR}/${SAMPLE}.${hap}.filt.fa
done

fastq_checker check \
    -i ${HAP1_OUTPUT} \
    -f fasta \
1>${HAP1_STATS} 2>/dev/null

fastq_checker check \
    -i ${HAP2_OUTPUT} \
    -f fasta \
1>${HAP2_STATS} 2>/dev/null

cat ${HAP1_OUTPUT} ${HAP2_OUTPUT} > ${COMBINED_OUTPUT}
samtools faidx ${COMBINED_OUTPUT}

echo ${?}
