#!/bin/bash
# Download and format the reference and annotation files required by the
# assembly workflow's annotation and evaluation modules.
#
# Usage: bash download_reference.sh [OUTDIR]
#   OUTDIR   destination directory for the references (default: reference)
#
# Fetches the two genome FASTAs (CHM13v2.0, GRCh38), the CHM13 CenSat BED,
# GRCh38 centromeres, GRCh38 GRC exclusions, and the Ensembl 112 GTF (reformatted
# to chr* contig names for Liftoff). The compleasm BUSCO lineage database needs
# the compleasm container and is downloaded separately by download_compleasm_db.sh.

set -o errexit
set -o nounset
set -o pipefail

OUTDIR="${1:-reference}"
mkdir -p "${OUTDIR}"

# CHM13v2.0 genome FASTA (decompressed to plain .fa).
wget -O "${OUTDIR}/chm13v2.0_maskedY_rCRS.fa.gz" \
  https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0_maskedY_rCRS.fa.gz
gunzip -f "${OUTDIR}/chm13v2.0_maskedY_rCRS.fa.gz"

# GRCh38 genome FASTA.
wget --content-disposition -O "${OUTDIR}/GRCh38.d1.vd1.fa.tar.gz" \
  'https://api.gdc.cancer.gov/data/254f697d-310d-4d7d-a27b-27fbf767a834'
tar xvzf "${OUTDIR}/GRCh38.d1.vd1.fa.tar.gz" -C "${OUTDIR}"

# CHM13 CenSat annotation BED (chain files).
wget -P "${OUTDIR}" \
  https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_censat_v2.1.bed

# GRCh38 centromeres (chain files).
wget -P "${OUTDIR}" \
  https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/centromeres.txt.gz

# GRCh38 GRC exclusion regions BED (chain files).
wget -P "${OUTDIR}" \
  https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed

# GRCh38 Ensembl 112 GTF for Liftoff, reformatted to chr* contig names.
wget -P "${OUTDIR}" \
  https://ftp.ensembl.org/pub/release-112/gtf/homo_sapiens/Homo_sapiens.GRCh38.112.chr.gtf.gz
zgrep -v "#" "${OUTDIR}/Homo_sapiens.GRCh38.112.chr.gtf.gz" \
  | sed 's/^\([0-9|X|Y|MT]\)/chr\1/' \
  | sed 's/^chrMT/chrM/' \
  > "${OUTDIR}/Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf"

echo "References written to ${OUTDIR}"
