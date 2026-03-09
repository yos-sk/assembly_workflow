#!/bin/bash

set -eux -o pipefail

INPUT_FASTA=$1
OUTPUT_DIR=$2
SCRIPTS_DIR=$3
PROJECT_DIR=$(pwd)

# Convert relative paths to absolute (before cd)
[[ "$INPUT_FASTA" != /* ]] && INPUT_FASTA="$PROJECT_DIR/$INPUT_FASTA"
[[ "$OUTPUT_DIR" != /* ]] && OUTPUT_DIR="$PROJECT_DIR/$OUTPUT_DIR"

WORK_DIR=${OUTPUT_DIR}/work
mkdir -p ${WORK_DIR}/Hsat

## Call annotation script (cd needed for HSat2_kmers.txt etc.)
## HSat2_kmers.txt and HSat3_kmers.txt are at /opt/chm13_hsat/ inside the container
cd /opt/chm13_hsat
perl ${SCRIPTS_DIR}/Assembly_HSat2and3_v3.pl $INPUT_FASTA ${WORK_DIR}/Hsat || true

## v0.3 of the script (rarely) creates regions that have start > stop such as:
## HG01786#2#CM089530.1 59222541        59222563        HSat2   0       -       59222541        59222563        51,51,102
## remove these to avoid problems downstream. In the future, fix the perl script.
for f in ${WORK_DIR}/Hsat/HSat2and3_Regions.bed; do awk -F'\t' '$2 <= $3' "$f" > ${OUTPUT_DIR}/HSat2and3_Regions.bed; done

# In case of empty output
if ! test -f ${OUTPUT_DIR}/HSat2and3_Regions.bed; 
       then echo -e 'chrFAKE\t0\t1\tHSat3\t0\t-\t0\t1\t120,161,187' > ${OUTPUT_DIR}/placeholder.HSat2and3_Regions.bed 
fi

echo ${?}
