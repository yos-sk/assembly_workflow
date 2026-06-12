#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

export BLASTDB_LMDB_MAP_SIZE=100000000

ASSEMBLY_FASTA=$1
OUTPUT_DIR=$2
THREADS=$3

mkdir -p ${OUTPUT_DIR}

# RepeatMasker rejects sequence identifiers longer than 50 characters
# (FastaDB::_cleanIndexAndCompact). PanSN-renamed contig names can exceed this,
# so rename to short placeholders (s1, s2, ...) before masking and restore the
# original identifiers in the result afterwards.
BASENAME=$(basename ${ASSEMBLY_FASTA})
WORK_DIR=${OUTPUT_DIR}/.rename_tmp.${BASENAME}
RENAMED_FASTA=${WORK_DIR}/${BASENAME}
ID_MAP=${WORK_DIR}/id_map.tsv

rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}

# Build short-id FASTA and a short-id -> original-id map (first header token).
awk -v map="${ID_MAP}" '
    /^>/ { n++; short="s" n; split(substr($0, 2), a, /[ \t]/);
           print short "\t" a[1] > map; print ">" short; next }
    { print }
' ${ASSEMBLY_FASTA} > ${RENAMED_FASTA}

RepeatMasker \
    -species human \
    -e rmblast \
    -pa ${THREADS} \
    ${RENAMED_FASTA} \
    -dir ${OUTPUT_DIR}

# RepeatMasker names its output after the input basename. Restore the original
# contig identifiers in column 5 (query sequence) of the .out file; the first
# three lines are the header and are passed through unchanged.
RMSK_OUT=${OUTPUT_DIR}/${BASENAME}.out
awk -v map="${ID_MAP}" '
    BEGIN { while ((getline l < map) > 0) { split(l, a, "\t"); m[a[1]] = a[2] } }
    NR <= 3 { print; next }
    { if ($5 in m) $5 = m[$5]; print }
' ${RMSK_OUT} > ${RMSK_OUT}.tmp && mv ${RMSK_OUT}.tmp ${RMSK_OUT}

rm -rf ${WORK_DIR}

echo ${?}
