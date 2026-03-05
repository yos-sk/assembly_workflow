#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

OUTPUT_DIR=$1
PAT_R1=$2
PAT_R2=$3
MAT_R1=$4
MAT_R2=$5
THREADS=$6

meryl count compress k=30 threads=${THREADS} ${PAT_R1} ${PAT_R2} output ${OUTPUT_DIR}/paternal_compress.k30.hapmer.meryl
meryl count compress k=30 threads=${THREADS} ${MAT_R1} ${MAT_R2} output ${OUTPUT_DIR}/maternal_compress.k30.hapmer.meryl

echo "#!/bin/bash" > ${OUTPUT_DIR}/run_merqury.sh
echo >> ${OUTPUT_DIR}/run_merqury.sh
echo "export MERQURY=/tools/merqury" >> ${OUTPUT_DIR}/run_merqury.sh
echo "/tools/merqury/trio/hapmers.sh paternal_compress.k30.hapmer.meryl maternal_compress.k30.hapmer.meryl " >> ${OUTPUT_DIR}/run_merqury.sh
cd ${OUTPUT_DIR} && bash run_merqury.sh

echo ${?}
