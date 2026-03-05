#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

INPUT_BAM=$1
INPUT_ASSEMBLY_HAP1=$2
INPUT_ASSEMBLY_HAP2=$3
WORK_DIR=$4
OUTPUT_DIR=$5
PLATFORM=$6 # HiFi or ONT-R9 or ONT-R10
THREADS=$7

mkdir -p ${WORK_DIR}


cat ${INPUT_ASSEMBLY_HAP1} ${INPUT_ASSEMBLY_HAP2} > ${WORK_DIR}/assembly.fa

samtools faidx ${WORK_DIR}/assembly.fa
cat ${WORK_DIR}/assembly.fa.fai | awk '{print $1"\t0\t"$2}' > ${WORK_DIR}/whole_genome.bed

echo "{" > ${WORK_DIR}/annotations_path.json
echo \"whole_genome\" : \"${WORK_DIR}/whole_genome.bed\" >> ${WORK_DIR}/annotations_path.json
echo "}" >> ${WORK_DIR}/annotations_path.json

echo "{" > ${WORK_DIR}/annotations_path.json
echo \"whole_genome\" : \"${WORK_DIR}/whole_genome.bed\" >> ${WORK_DIR}/annotations_path.json
echo "}" >> ${WORK_DIR}/annotations_path.json


bam2cov --bam ${INPUT_BAM} \
        --output ${WORK_DIR}/coverage_file.cov.gz \
        --annotationJson ${WORK_DIR}/annotations_path.json \
        --threads ${THREADS} \
        --baselineAnnotation whole_genome

mkdir -p ${OUTPUT_DIR}
if [ $PLATFORM = "hifi" ]; then
    hmm_flagger \
        --input ${WORK_DIR}/coverage_file.cov.gz \
        --outputDir ${OUTPUT_DIR} \
        --alphaTsv /models/alpha_optimum_trunc_exp_gaussian_w_16000_n_50.HiFi_DC_1.2_DEC_2024.v1.1.0.tsv \
        --windowLen 16000 \
        --labelNames Err,Dup,Hap,Col \
        --threads ${THREADS}
elif [ $PLATFORM = "ont-r9" ]; then
    hmm_flagger \
        --input ${WORK_DIR}/coverage_file.cov.gz \
        --outputDir ${OUTPUT_DIR} \
        --alphaTsv /models/alpha_optimum_trunc_exp_gaussian_w_16000_n_50.ONT_R941_Guppy6.3.7_DEC_2024.v1.1.0.tsv \
        --windowLen 16000 \
        --labelNames Err,Dup,Hap,Col \
        --threads ${THREADS}
elif [ $PLATFORM = "ont-r10" ]; then
    hmm_flagger \
        --input ${WORK_DIR}/coverage_file.cov.gz \
        --outputDir ${OUTPUT_DIR} \
        --alphaTsv /models/alpha_optimum_trunc_exp_gaussian_w_8000_n_50.ONT_R1041_Dorado_DEC_2024.v1.1.0.tsv \
        --windowLen 8000 \
        --labelNames Err,Dup,Hap,Col \
        --threads ${THREADS}
else
    echo "$PLATFORM is not as expected!"
    exit 1
fi

rm ${WORK_DIR}/assembly.fa

echo ${?}
