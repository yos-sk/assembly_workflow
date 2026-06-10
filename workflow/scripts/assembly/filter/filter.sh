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
MIN_LENGTH=${15}

DNA_NN_MODEL="/opt/dna-nn-0.1/models/attcc-alpha.knm"

mkdir -p ${WORK_DIR}
mkdir -p ${OUTPUT_DIR}

REFERENCE_FASTA=${REFERENCE}
if [ ${SEX} = "female" ]; then
    # Female (XX): drop chrY from the reference so contigs are not assigned to it.
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${REFERENCE} > ${WORK_DIR}/reference_noY.fa
    REFERENCE_FASTA=${WORK_DIR}/reference_noY.fa
fi

# Length filtering: keep contigs >= MIN_LENGTH.
seqtk seq -L ${MIN_LENGTH} ${HAP1_INPUT} > ${WORK_DIR}/${SAMPLE}.hap1.filt.fa
seqtk seq -L ${MIN_LENGTH} ${HAP2_INPUT} > ${WORK_DIR}/${SAMPLE}.hap2.filt.fa

# --------------------------------------------------------------------
# Phase A: per haplotype, mask + align + build a raw reference table
# --------------------------------------------------------------------
for hap in hap1 hap2; do
    INPUT_FASTA=${WORK_DIR}/${SAMPLE}.${hap}.filt.fa

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

    minimap2 -cx asm5 -t ${THREADS} \
        ${WORK_DIR}/${SAMPLE}.${hap}.masked.fa \
        ${REFERENCE_FASTA} \
    > ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.paf
    grep -v 'tp:A:S' ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.paf > ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.rmsec.paf

    python3 ${SCRIPTS_DIR}/assembly/filter/make_reference_table.py \
        -i ${WORK_DIR}/${SAMPLE}.${hap}.masked_ref.rmsec.paf \
    > ${WORK_DIR}/${SAMPLE}.${hap}.ref.table.raw
done

# --------------------------------------------------------------------
# Phase B: sex-chromosome consolidation (male only)
# Consolidate chrX onto one haplotype and chrY onto the other; this can move
# sex-chromosome records between the two reference tables. The final tables are
# written to OUTPUT_DIR. Female (XX) tables are used as-is.
# --------------------------------------------------------------------
if [ ${SEX} = "male" ]; then
    python3 ${SCRIPTS_DIR}/assembly/filter/postprocess_sex_chrom.py \
        --hap1 ${WORK_DIR}/${SAMPLE}.hap1.ref.table.raw \
        --hap2 ${WORK_DIR}/${SAMPLE}.hap2.ref.table.raw \
        --out1 ${OUTPUT_DIR}/${SAMPLE}.hap1.ref.table \
        --out2 ${OUTPUT_DIR}/${SAMPLE}.hap2.ref.table
else
    cp ${WORK_DIR}/${SAMPLE}.hap1.ref.table.raw ${OUTPUT_DIR}/${SAMPLE}.hap1.ref.table
    cp ${WORK_DIR}/${SAMPLE}.hap2.ref.table.raw ${OUTPUT_DIR}/${SAMPLE}.hap2.ref.table
fi

# --------------------------------------------------------------------
# Phase C: orient + rename per output haplotype
# Sequences are pulled from a pool of both haplotypes so that sex-chromosome
# contigs moved in Phase B end up in the haplotype their final table assigns.
# Contigs assigned to no chromosome stay in their original haplotype.
# --------------------------------------------------------------------
cat ${WORK_DIR}/${SAMPLE}.hap1.filt.fa ${WORK_DIR}/${SAMPLE}.hap2.filt.fa > ${WORK_DIR}/${SAMPLE}.pool.fa
cut -f1 ${OUTPUT_DIR}/${SAMPLE}.hap1.ref.table ${OUTPUT_DIR}/${SAMPLE}.hap2.ref.table \
    | sort -u > ${WORK_DIR}/${SAMPLE}.assigned.all.list

for hap in hap1 hap2; do
    if [ $hap = "hap1" ]; then
        HAPNUM=1
    else
        HAPNUM=2
    fi
    INPUT_FASTA=${WORK_DIR}/${SAMPLE}.${hap}.filt.fa
    TABLE=${OUTPUT_DIR}/${SAMPLE}.${hap}.ref.table

    samtools faidx ${INPUT_FASTA}

    # Contigs assigned to this haplotype, split by strand.
    cut -f1 ${TABLE} | sort -u > ${WORK_DIR}/${SAMPLE}.${hap}.assigned.list
    awk -F'\t' '$4=="-"{print $1}' ${TABLE} | sort -u > ${WORK_DIR}/${SAMPLE}.${hap}.minus.list
    comm -23 ${WORK_DIR}/${SAMPLE}.${hap}.assigned.list ${WORK_DIR}/${SAMPLE}.${hap}.minus.list \
        > ${WORK_DIR}/${SAMPLE}.${hap}.assigned_fwd.list

    # Contigs of this haplotype not assigned to any chromosome (kept as-is).
    cut -f1 ${INPUT_FASTA}.fai | sort -u > ${WORK_DIR}/${SAMPLE}.${hap}.allctg.list
    comm -23 ${WORK_DIR}/${SAMPLE}.${hap}.allctg.list ${WORK_DIR}/${SAMPLE}.assigned.all.list \
        > ${WORK_DIR}/${SAMPLE}.${hap}.unassigned.list

    : > ${WORK_DIR}/${SAMPLE}.${hap}.oriented.fa
    if [ -s ${WORK_DIR}/${SAMPLE}.${hap}.assigned_fwd.list ]; then
        seqtk subseq ${WORK_DIR}/${SAMPLE}.pool.fa ${WORK_DIR}/${SAMPLE}.${hap}.assigned_fwd.list \
            >> ${WORK_DIR}/${SAMPLE}.${hap}.oriented.fa
    fi
    if [ -s ${WORK_DIR}/${SAMPLE}.${hap}.minus.list ]; then
        seqtk subseq ${WORK_DIR}/${SAMPLE}.pool.fa ${WORK_DIR}/${SAMPLE}.${hap}.minus.list \
            | seqtk seq -r \
            >> ${WORK_DIR}/${SAMPLE}.${hap}.oriented.fa
    fi
    if [ -s ${WORK_DIR}/${SAMPLE}.${hap}.unassigned.list ]; then
        seqtk subseq ${INPUT_FASTA} ${WORK_DIR}/${SAMPLE}.${hap}.unassigned.list \
            >> ${WORK_DIR}/${SAMPLE}.${hap}.oriented.fa
    fi

    # Rename to PanSN-style {sample}#{hap}#{chrom}.
    python3 ${SCRIPTS_DIR}/assembly/filter/rename_contig.py \
        -r ${TABLE} \
        -f ${WORK_DIR}/${SAMPLE}.${hap}.oriented.fa \
        -s ${SAMPLE} \
        -p ${HAPNUM} \
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
