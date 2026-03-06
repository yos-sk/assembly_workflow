#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
HAP1_ASSEMBLY=$2
HAP2_ASSEMBLY=$3
ASSEMBLER=$4
SEX=$5
REFERENCE_DIR=$6
WORK_DIR=$7
OUTPUT_DIR=$8

mkdir -p $WORK_DIR
mkdir -p $OUTPUT_DIR

for reference in GRCh38 chm13; do
    if [ $SEX = "female" ]; then
        reference_fasta=${REFERENCE_DIR}/${reference}.masked_noY.fa
    else
        reference_fasta=${REFERENCE_DIR}/${reference}.masked.fa
    fi
    for hap in hap1 hap2; do
        if [ $hap = "hap1" ]; then
            assemble=$HAP1_ASSEMBLY
        else
            assemble=$HAP2_ASSEMBLY
        fi

        # chainfiles to convert assembly to chm13/GRCh38
        minimap2 -cx asm5 -t 8 ${assemble} ${reference_fasta} \
            > ${WORK_DIR}/${SAMPLE}_${hap}.${reference}.paf
        transanno minimap2chain \
            ${WORK_DIR}/${SAMPLE}_${hap}.${reference}.paf \
            --output ${WORK_DIR}/${SAMPLE}_${hap}.${reference}.chain

        # chainfiles to convert chm13/GRCh38 to assembly
        minimap2 -cx asm5 -t 8 ${reference_fasta} ${assemble} \
            > ${WORK_DIR}/${reference}.${SAMPLE}_${hap}.paf
        transanno minimap2chain \
            ${WORK_DIR}/${reference}.${SAMPLE}_${hap}.paf \
            --output ${WORK_DIR}/${reference}.${SAMPLE}_${hap}.chain
    done
done

for reference in GRCh38 chm13; do
    if [ $SEX = "female" ]; then
        reference_fasta=${REFERENCE_DIR}/${reference}.masked_noY.fa
    else
        reference_fasta=${REFERENCE_DIR}/${reference}.masked.fa
    fi
    for hap in hap1 hap2; do
        # chainfiles to convert assembly to chm13/GRCh38
        python3 /tools/chaintools/chaintools/split.py \
            -c ${WORK_DIR}/${SAMPLE}_${hap}.${reference}.chain \
            -o ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-split.chain
        if [ $hap = "hap1" ]; then
            assemble=$HAP1_ASSEMBLY
        else
            assemble=$HAP2_ASSEMBLY
        fi
        python3 /tools/chaintools/chaintools/to_paf.py \
            -c ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-split.chain \
            -t ${reference_fasta} \
            -q ${assemble} \
            -o ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-split.paf
        cat ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-split.paf | \
            rb break-paf --max-size 10000 | rb trim-paf -r | rb invert | rb trim-paf -r | rb invert \
        > ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-out.paf
        paf2chain -i ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-out.paf \
            > ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-out.chain
        python3 /tools/chaintools/chaintools/invert.py \
            -c ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-out.chain \
            -o ${WORK_DIR}/${SAMPLE}_${hap}.${reference}-out_inverted.chain

        # chainfiles to convert chm13/GRCh38 to assembly
        python3 /tools/chaintools/chaintools/split.py \
            -c ${WORK_DIR}/${reference}.${SAMPLE}_${hap}.chain \
            -o ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-split.chain
        if [ $hap = "hap1" ]; then
            assemble=$HAP1_ASSEMBLY
        else
            assemble=$HAP2_ASSEMBLY
        fi
        python3 /tools/chaintools/chaintools/to_paf.py \
            -c ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-split.chain \
            -q ${reference_fasta} \
            -t ${assemble} \
            -o ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-split.paf
        SPLIT_DIR=${WORK_DIR}/${reference}/split_${hap}
        mkdir -p ${SPLIT_DIR}
        sort -k 1,1 -k 2,2n ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-split.paf \
            > ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-split.sorted.paf
        awk -v out_dir="$SPLIT_DIR" 'NR%1000==1{x=out_dir"/"++i".paf"} {print > x}' \
            ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-split.sorted.paf
        find ${SPLIT_DIR} -type f -name "*.paf" | while read f; do
            cat ${f} | rb break-paf --max-size 10000 | rb trim-paf -r | rb invert | rb trim-paf -r | rb invert \
                > ${f%.paf}-out.paf
            paf2chain -i ${f%.paf}-out.paf > ${f%.paf}-out.chain
            python3 /tools/chaintools/chaintools/invert.py \
                -c ${f%.paf}-out.chain \
                -o ${f%.paf}-out_inverted.chain
        done
        cat ${SPLIT_DIR}/*-out_inverted.chain > ${WORK_DIR}/${reference}.${SAMPLE}_${hap}-out_inverted.chain
    done
    cat ${WORK_DIR}/${SAMPLE}_hap1.${reference}-out_inverted.chain ${WORK_DIR}/${SAMPLE}_hap2.${reference}-out_inverted.chain \
        > ${OUTPUT_DIR}/${SAMPLE}_to_${reference}.chain
    cat ${WORK_DIR}/${reference}.${SAMPLE}_hap1-out_inverted.chain ${WORK_DIR}/${reference}.${SAMPLE}_hap2-out_inverted.chain \
        > ${OUTPUT_DIR}/${reference}_to_${SAMPLE}.chain
done

echo ${?}
