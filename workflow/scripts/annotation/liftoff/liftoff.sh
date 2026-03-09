#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail


SAMPLE=$1
ASSEMBLER=$2
HAP1_ASSEMBLE=$3
HAP2_ASSEMBLE=$4
SEX=$5
GRCH38=$6
GRCH38_GTF=$7
OUTPUT_DIR=$8
THREADS=$9

WORK_DIR=${OUTPUT_DIR}/workspace

mkdir -p ${OUTPUT_DIR}
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}

if [ ${SEX} = "female" ]; then
    awk '/^>/ {p = ($0 !~ /^>chrY/)} p' ${GRCH38} > ${WORK_DIR}/GRCh38_noY.fa
    GRCH38=${WORK_DIR}/GRCh38_noY.fa
    base_name=`basename ${GRCH38_GTF}`
    grep -v "chrY" ${GRCH38_GTF} > ${WORK_DIR}/${base_name%.gtf}_noY.gtf
    GRCH38_GTF=${WORK_DIR}/${base_name%.gtf}_noY.gtf
fi


for hap in hap1 hap2; do 
    if [ $hap = "hap1" ]; then
        ASSEMBLE=$HAP1_ASSEMBLE
    else
        ASSEMBLE=$HAP2_ASSEMBLE
    fi
    liftoff \
        -g ${GRCH38_GTF} \
        -o ${WORK_DIR}/${SAMPLE}.${hap}.Ensembl_GRCh38.liftoff.gff \
        -u ${WORK_DIR}/${hap}.unmapped_features.txt \
        -dir ${WORK_DIR} \
        -p ${THREADS} \
        -m /usr/local/bin/minimap2 \
        ${ASSEMBLE} \
        ${GRCH38} 

    awk '{if ($3 == "gene") print}'  \
        ${WORK_DIR}/${SAMPLE}.${hap}.Ensembl_GRCh38.liftoff.gff | \
            grep -v pseudogene | \
            grep gene_name | \
            awk '{gsub( /[";]/, ""); print $1 "\t" $4 - 1 "\t" $5 "\t" $14 "\t"  $7 "\t" $10 "\t" $18}' \
    > ${WORK_DIR}/${SAMPLE}.${hap}.Ensembl_GRCh38.liftoff.bed
done


cat ${WORK_DIR}/${SAMPLE}.hap1.Ensembl_GRCh38.liftoff.bed ${WORK_DIR}/${SAMPLE}.hap2.Ensembl_GRCh38.liftoff.bed | \
    sort -k 1,1 -k 2,2n | bgzip -f -c \
> ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.bed.gz
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.bed.gz


cat ${WORK_DIR}/${SAMPLE}.hap1.Ensembl_GRCh38.liftoff.gff ${WORK_DIR}/${SAMPLE}.hap2.Ensembl_GRCh38.liftoff.gff |\
    grep -v "#" |\
    sort -k1,1 -k4,4n -k5,5n -t$'\t' \
> ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.gff

gffread ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.gff -T -o ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.gtf
bgzip -f ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.gtf

bgzip -f ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.gff
tabix -p gff ${OUTPUT_DIR}/${SAMPLE}.Ensembl_GRCh38.liftoff.gff.gz

echo ${?}
