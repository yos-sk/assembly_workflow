#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

ILLUMINA_READ1=$1
ILLUMINA_READ2=$2
ASSEMBLY_FASTA_HAP1=$3
ASSEMBLY_FASTA_HAP2=$4
MERQURY_DB=$5
OUTPUT_DIR=$6
THREADS=$7

mkdir -p ${MERQURY_DB}
if [ ! -d ${MERQURY_DB}/READS_DB.meryl ]; then
    meryl k=21 count threads=${THREADS} ${ILLUMINA_READ1} ${ILLUMINA_READ2} output ${MERQURY_DB}/READS_DB.meryl
fi

PWD=`pwd`

MERQURY_DB_DIR=`cd ${MERQURY_DB} && pwd`
cd $PWD
mkdir -p ${OUTPUT_DIR}
echo "#!/bin/bash" > ${OUTPUT_DIR}/run_merqury.sh
echo >> ${OUTPUT_DIR}/run_merqury.sh
echo "export MERQURY=/tools/merqury" >> ${OUTPUT_DIR}/run_merqury.sh 
echo "merqury.sh ${MERQURY_DB_DIR}/READS_DB.meryl ${ASSEMBLY_FASTA_HAP1} ${ASSEMBLY_FASTA_HAP2} out" >> ${OUTPUT_DIR}/run_merqury.sh
cd ${OUTPUT_DIR} && bash run_merqury.sh

echo ${?}

