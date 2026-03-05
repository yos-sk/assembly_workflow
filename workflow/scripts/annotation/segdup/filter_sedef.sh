#!/bin/bash
#SBATCH -c 1
#SBATCH --mem-per-cpu=10G

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
INPUT_BED_HAP1=$2
INPUT_BED_HAP2=$3
OUTPUT_DIR=$4
REPEAT_MASKER_HAP1=$5
REPEAT_MASKER_HAP2=$6
FAIDX_HAP1=$7
FAIDX_HAP2=$8
SCRIPTS_DIR=$9

WORK_DIR=${OUTPUT_DIR}/workspace
mkdir -p ${WORK_DIR} 

grep Satellite ${REPEAT_MASKER_HAP1} | cut -f 1-3 | bedtools sort -i - | bedtools merge -i - | \
    bedtools coverage -header -a ${INPUT_BED_HAP1} -b - > ${WORK_DIR}/tmp.sat.count.hap1.bed
grep "^#" ${INPUT_BED_HAP1} > ${OUTPUT_DIR}/final.sat.count.hap1.bed
cat ${WORK_DIR}/tmp.sat.count.hap1.bed >> ${OUTPUT_DIR}/final.sat.count.hap1.bed
sed -i '1{{s/$/\tcount_ovls\tsat_bases\ttotal_bases\tsat_coverage/}}' ${OUTPUT_DIR}/final.sat.count.hap1.bed

grep Satellite ${REPEAT_MASKER_HAP2} | cut -f 1-3 | bedtools sort -i - | bedtools merge -i - | \
    bedtools coverage -header -a ${INPUT_BED_HAP2} -b - > ${WORK_DIR}/tmp.sat.count.hap2.bed
grep "^#" ${INPUT_BED_HAP2} > ${OUTPUT_DIR}/final.sat.count.hap2.bed
cat ${WORK_DIR}/tmp.sat.count.hap2.bed >> ${OUTPUT_DIR}/final.sat.count.hap2.bed
sed -i '1{{s/$/\tcount_ovls\tsat_bases\ttotal_bases\tsat_coverage/}}' ${OUTPUT_DIR}/final.sat.count.hap2.bed

python3 ${SCRIPTS_DIR}/annotation/segdup/filter_sedef.py \
    -i ${OUTPUT_DIR}/final.sat.count.hap1.bed \
> ${WORK_DIR}/${SAMPLE}.hap1.filtered.bed

python3 ${SCRIPTS_DIR}/annotation/segdup/filter_sedef.py \
    -i ${OUTPUT_DIR}/final.sat.count.hap2.bed \
> ${WORK_DIR}/${SAMPLE}.hap2.filtered.bed


awk '{print $1 "\t" $2 "\t" $3 "\t" $8 "\n" $4 "\t" $5 "\t" $6 "\t" $8}' ${WORK_DIR}/${SAMPLE}.hap1.filtered.bed \
 | sort -k 1,1 -k 2,2n -k 3,3n > ${WORK_DIR}/${SAMPLE}.hap1.segdup.sep.bed

bedtools merge -i ${WORK_DIR}/${SAMPLE}.hap1.segdup.sep.bed > ${WORK_DIR}/${SAMPLE}.hap1.segdup.sep.merge.bed

awk '{print $1 "\t" $2 "\t" $3 "\t" $8 "\n" $4 "\t" $5 "\t" $6 "\t" $8}' ${WORK_DIR}/${SAMPLE}.hap2.filtered.bed \
 | sort -k 1,1 -k 2,2n -k 3,3n > ${WORK_DIR}/${SAMPLE}.hap2.segdup.sep.bed

bedtools merge -i ${WORK_DIR}/${SAMPLE}.hap2.segdup.sep.bed > ${WORK_DIR}/${SAMPLE}.hap2.segdup.sep.merge.bed

bgzip -f ${WORK_DIR}/${SAMPLE}.hap1.segdup.sep.bed 
tabix -p bed ${WORK_DIR}/${SAMPLE}.hap1.segdup.sep.bed.gz

bgzip -f ${WORK_DIR}/${SAMPLE}.hap2.segdup.sep.bed 
tabix -p bed ${WORK_DIR}/${SAMPLE}.hap2.segdup.sep.bed.gz

cat ${WORK_DIR}/${SAMPLE}.hap1.filtered.bed ${WORK_DIR}/${SAMPLE}.hap2.filtered.bed | sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.filtered.bed
bgzip -f ${OUTPUT_DIR}/${SAMPLE}.filtered.bed
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.filtered.bed.gz

total=`awk '{len += $2} END {print len}' ${FAIDX_HAP1}`
sd=`awk '{len += $3 - $2} END {print len}' ${WORK_DIR}/${SAMPLE}.hap1.segdup.sep.merge.bed`
rate=`bc <<< "scale=4; $sd/$total * 100"`

echo -e "${sd}\t${total}\t${rate}\thap1" > ${OUTPUT_DIR}/${SAMPLE}.segdup.len.summary.txt

total=`awk '{len += $2} END {print len}' ${FAIDX_HAP2}`
sd=`awk '{len += $3 - $2} END {print len}' ${WORK_DIR}/${SAMPLE}.hap2.segdup.sep.merge.bed`
rate=`bc <<< "scale=4; $sd/$total * 100"`

echo -e "${sd}\t${total}\t${rate}\thap2" >> ${OUTPUT_DIR}/${SAMPLE}.segdup.len.summary.txt

echo ${?}
