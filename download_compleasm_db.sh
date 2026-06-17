#!/bin/bash
# Download a compleasm BUSCO library (version index + lineage dataset) for use
# with --compleasm-library, so compleasm's run path finds the lineage locally and
# never hits its broken placement download.
#
# We do NOT use compleasm's own `compleasm download <lineage>`: its run path builds
# a Downloader that parses every placement entry in file_versions.tsv, and a recent
# BUSCO addition (eukaryota_odb12.2.*, whose name carries an extra dot) crashes its
# parser with
#   ValueError: too many values to unpack (expected 3)
# (compleasm issue #61: https://github.com/huangnengCSU/compleasm/issues/61).
# Placement files are only used for auto-lineage selection, never for an explicit
# `-l <lineage>` run, so we strip ALL placement_files rows from the LOCAL
# file_versions.tsv: download_placement() then iterates an empty list — no crash,
# no download (works offline).
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

# --- BUSCO version index: <OUTDIR>/file_versions.tsv (+ .done) ---
# Drop every placement_files row so compleasm's download_placement() has nothing to
# iterate (and cannot choke on eukaryota_odb12.2.*). Idempotent: also repairs a full
# index left by an earlier run. The .done marker makes compleasm read this local
# copy instead of re-downloading the unfiltered upstream index.
FILE_VERSIONS="${OUTDIR}/file_versions.tsv"
if [ ! -e "${FILE_VERSIONS}" ]; then
    wget -O "${FILE_VERSIONS}" "${BASE_URL}/file_versions.tsv"
fi
awk -F'\t' '$NF!="placement_files"' "${FILE_VERSIONS}" > "${FILE_VERSIONS}.filt"
mv "${FILE_VERSIONS}.filt" "${FILE_VERSIONS}"
touch "${FILE_VERSIONS}.done"

# --- Lineage dataset: <OUTDIR>/<lineage>/ + <lineage>.done ---
if [ -e "${OUTDIR}/${LINEAGE}.done" ]; then
    echo "compleasm lineage ${LINEAGE} already present in ${OUTDIR}"
else
    DATE=$(awk -v l="${LINEAGE}" '$1==l && $NF=="lineages"{print $2; exit}' "${FILE_VERSIONS}")
    if [ -z "${DATE}" ]; then
        echo "error: lineage '${LINEAGE}' not found in file_versions.tsv" >&2
        exit 1
    fi
    wget -O "${OUTDIR}/${LINEAGE}.tar.gz" "${BASE_URL}/lineages/${LINEAGE}.${DATE}.tar.gz"
    tar xzf "${OUTDIR}/${LINEAGE}.tar.gz" -C "${OUTDIR}"
    rm -f "${OUTDIR}/${LINEAGE}.tar.gz"
    touch "${OUTDIR}/${LINEAGE}.done"
    echo "compleasm lineage ${LINEAGE} (${DATE}) written to ${OUTDIR}/${LINEAGE}"
fi

# --- Placement: neutralized (not needed for an explicit -l run) ---
# With no placement rows in the index, download_placement() is a no-op. Provide the
# dir + .done marker (skips the call on builds that honour it) and clear any stale
# lock left by a previously failed run.
rm -f "${OUTDIR}/placement_files.tmp"
mkdir -p "${OUTDIR}/placement_files"
touch "${OUTDIR}/placement_files.done"

echo "compleasm library ready in ${OUTDIR} (placement disabled; lineage=${LINEAGE})"
