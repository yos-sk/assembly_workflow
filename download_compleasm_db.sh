#!/bin/bash
# Download a compleasm BUSCO lineage dataset for use with --compleasm-library.
#
# compleasm's own `compleasm download <lineage>` command is currently broken: it
# always fetches BUSCO "placement" files, and a recent change to BUSCO's
# file_versions.tsv makes its filename parser crash with
#   ValueError: too many values to unpack (expected 3)
# (compleasm issue #61: https://github.com/huangnengCSU/compleasm/issues/61).
# The workflow only ever runs compleasm with an explicit -l <lineage>, which
# needs just the lineage dataset and no placement files. So we download that
# dataset directly from BUSCO and lay it out exactly as `compleasm download`
# would: <OUTDIR>/<lineage>/ plus a <lineage>.done marker.
#
# Usage: bash download_compleasm_db.sh [OUTDIR] [LINEAGE]
#   OUTDIR    destination library directory (default: reference/mb_downloads)
#   LINEAGE   BUSCO lineage to download (default: primates_odb10)

set -o errexit
set -o nounset
set -o pipefail

OUTDIR="${1:-reference/mb_downloads}"
LINEAGE="${2:-primates_odb10}"
BASE_URL="https://busco-data.ezlab.org/v5/data"

mkdir -p "${OUTDIR}"

if [ -e "${OUTDIR}/${LINEAGE}.done" ]; then
    echo "compleasm lineage ${LINEAGE} already present in ${OUTDIR}"
    exit 0
fi

# Resolve the dated tarball name for this lineage from BUSCO's version index.
DATE=$(wget -qO- "${BASE_URL}/file_versions.tsv" \
       | awk -v l="${LINEAGE}" '$1==l && $NF=="lineages"{print $2; exit}')
if [ -z "${DATE}" ]; then
    echo "error: lineage '${LINEAGE}' not found in file_versions.tsv" >&2
    exit 1
fi

# Download and extract into <OUTDIR>/<lineage>/, matching `compleasm download`.
wget -O "${OUTDIR}/${LINEAGE}.tar.gz" "${BASE_URL}/lineages/${LINEAGE}.${DATE}.tar.gz"
tar xzf "${OUTDIR}/${LINEAGE}.tar.gz" -C "${OUTDIR}"
rm -f "${OUTDIR}/${LINEAGE}.tar.gz"
touch "${OUTDIR}/${LINEAGE}.done"

echo "compleasm lineage ${LINEAGE} (${DATE}) written to ${OUTDIR}/${LINEAGE}"
