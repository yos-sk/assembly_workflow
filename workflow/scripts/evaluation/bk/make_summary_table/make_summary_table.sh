#!/bin/bash
#SBATCH -c 1
#SBATCH --mem-per-cpu=8G
#SBATCH -p mjobs,rjobs

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
ASSEMBLER=$2
INPUT_ASSEMBLY_HAP1_STATS=$3
INPUT_ASSEMBLY_HAP2_STATS=$4
MERQURY=$5
MERGE_ERROR_HP1=$6
MERGE_ERROR_HP2=$7
COMPLEASM_HP1=$8
COMPLEASM_HP2=$9
T2T_HP1=${10}
T2T_HP2=${11}
OUTPUT_DIR=${12}

mkdir -p ${OUTPUT_DIR}
python make_summary_table/make_summary_table.py \
    -s ${SAMPLE} \
    -l ${ASSEMBLER} \
    -a ${INPUT_ASSEMBLY_HAP1_STATS} \
    -b ${INPUT_ASSEMBLY_HAP2_STATS} \
    -c ${MERQURY} \
    -d ${MERGE_ERROR_HP1} \
    -d ${MERGE_ERROR_HP2} \
    -f ${COMPLEASM_HP1} \
    -g ${COMPLEASM_HP2} \
    -i ${T2T_HP1} \
    -j ${T2T_HP2} \
> ${OUTPUT_DIR}/assembly_summary_stats.txt

echo ${?}

