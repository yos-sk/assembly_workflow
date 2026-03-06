#!/bin/bash

set -eux -o pipefail

OUTPUT_DIR=$1
SAMPLE=$2
rmsk_bed=$3
alphasat_bed=$4
strand_bed=$5
hsat_bed=$6
rdna_bed=$7
gaps_bed=$8
SCRIPTS_DIR=$9


WORK_DIR=${OUTPUT_DIR}/work/annotation
mkdir -p ${WORK_DIR}

cp ${SCRIPTS_DIR}/annotation/censat/create_annotations.sh ${WORK_DIR}
cp ${rmsk_bed} ${WORK_DIR}
cp ${alphasat_bed} ${WORK_DIR}
cp ${strand_bed} ${WORK_DIR}
cp ${hsat_bed} ${WORK_DIR}
cp ${rdna_bed} ${WORK_DIR}
cp ${gaps_bed} ${WORK_DIR}

cd ${WORK_DIR} && \
bash create_annotations.sh \
    ${SAMPLE}_rm.bed \
    summary_alphaSat.bed \
    strand.bed \
    HSat2and3_Regions.bed \
    rDNA.bed \
    gaps.filtered.bed \
    ${SAMPLE} && \
cp ${SAMPLE}.sorted.resolved_overlaps.bed ../../ && \
cp ${SAMPLE}.cenSat.bed ../../ && \
cp ${SAMPLE}.SatelliteStrand.bed ../../ && \
cp ${SAMPLE}.active.centromeres.bed ../../ && cd ../../

uniq ${SAMPLE}.sorted.resolved_overlaps.bed | bgzip -f -c > ${SAMPLE}.sorted.resolved_overlaps.bed.gz
tabix -p bed ${SAMPLE}.sorted.resolved_overlaps.bed.gz

tail -n +2 ${SAMPLE}.cenSat.bed | uniq | bgzip -f -c > ${SAMPLE}.cenSat.bed.gz
tabix -p bed ${SAMPLE}.cenSat.bed.gz

tail -n +2 ${SAMPLE}.SatelliteStrand.bed | uniq | bgzip -f -c > ${SAMPLE}.SatelliteStrand.bed.gz
tabix -p bed ${SAMPLE}.SatelliteStrand.bed.gz

uniq ${SAMPLE}.active.centromeres.bed | bgzip -f -c > ${SAMPLE}.active.centromeres.bed.gz
tabix -p bed ${SAMPLE}.active.centromeres.bed.gz

rm ${SAMPLE}.cenSat.bed
rm ${SAMPLE}.SatelliteStrand.bed


echo ${?}
