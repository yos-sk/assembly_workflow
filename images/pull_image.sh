#!/bin/bash
# Pull every singularity image the assembly workflow needs into this directory.
#
# File names follow `<image-key>.sif`, where <image-key> matches the keys
# referenced in workflow/ rules (e.g. config["images"]["repeatmasker"]) and
# the `_IMAGE_KEYS` list in setup_workflow.py. With every image staged under
# the same dir using these names, `setup_workflow.py --images-dir <dir>` is
# enough — no per-image override flags needed.
#
# Usage (run from this images/ directory):
#   cd images
#   bash pull_image.sh              # pull missing images
#   bash pull_image.sh --force      # re-pull everything
#   bash pull_image.sh hifiasm yak  # pull just these keys
#
# Notes:
# - Requires `singularity` (or `apptainer`) on PATH.
# - Locally-built images (yosakam2/*) live on Docker Hub
# - Upstream juklucas/* images come from the T2T cenSatAnnotation pipeline.

set -euo pipefail

# (image-key, docker URI). Each entry produces <key>.sif in this directory.
declare -a IMAGES=(
    # Assembly
    "hifiasm           yosakam2/hifiasm:v0.25.0"
    "verkko            yosakam2/verkko:v2.2.1"
    "yak               yosakam2/yak:v0.1"
    "merqury           yosakam2/merqury:1ad7c32"
    # Filtering / DNA-NN (shared image)
    "assembly_filter   yosakam2/dna-nn:v0.1"
    "dna_nn            yosakam2/dna-nn:v0.1"
    # Annotation
    "chain_files       yosakam2/chaintools:2a3b47e"
    "liftoff           yosakam2/liftoff:1.6.3"
    "trf_mod           yosakam2/trf-mod:3e891db"
    "sedef             yosakam2/sedef:latest"
    "repeatmasker      yosakam2/tetools:1.88.5"
    # CenSat annotation: locally-built
    "censat_alphasat   yosakam2/censat_alpha:v0.1"
    "censat_hmmer      yosakam2/censat_alpha:v0.1"
    "censat_tools      yosakam2/censat_tools:v0.1"
    # CenSat annotation: upstream T2T images
    "censat_hsat            juklucas/identify_hsat2and3:latest"
    "censat_rm2bed          humanpangenomics/rm2bed:latest"
    "censat_asat_summarize  juklucas/alphasat_summarize:latest"
    # Evaluation
    "alignment   yosakam2/minimap2:v2.28"
    "flagger     yosakam2/flagger:v1.1.0"
    "inspector   yosakam2/inspector:v1.3"
    "nucflag     yosakam2/nucflag:v0.3.3"
    "compleasm   huangnengcsu/compleasm:v0.2.8"
    "mashmap     yosakam2/mashmap:v3.1.3"
    "pstools     yosakam2/pstools:v0.2a3"
)

FORCE=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=1 ;;
        -h|--help)
            sed -n '1,/^set -euo pipefail/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) SELECT+=("$arg") ;;
    esac
done

# Pick singularity or apptainer (after arg parsing so --help works on hosts
# without either installed).
if command -v singularity >/dev/null 2>&1; then
    SING=singularity
elif command -v apptainer >/dev/null 2>&1; then
    SING=apptainer
else
    echo "Error: neither singularity nor apptainer is on PATH" >&2
    exit 1
fi

# Images are written to the current directory; run this script from images/.
OUT_DIR="."

pull_one() {
    local key="$1"
    local uri="$2"
    local out="$OUT_DIR/${key}.sif"
    if [[ -f "$out" && $FORCE -eq 0 ]]; then
        echo "[skip ] $key  (already at $out)"
        return 0
    fi
    echo "[pull ] $key  ←  docker://$uri"
    # --force is needed in case a partial download exists; singularity pull
    # otherwise refuses to overwrite.
    "$SING" pull --force "$out" "docker://$uri"
}

# Build a key->uri map preserving order. (Bash 3 on macOS lacks declare -A
# array literals, so we iterate the array directly.)
for line in "${IMAGES[@]}"; do
    # Split on whitespace; first token = key, last token = uri.
    read -r key uri <<<"$line"
    if [[ ${#SELECT[@]} -gt 0 ]]; then
        # When the user asked for specific keys, skip everything else.
        match=0
        for s in "${SELECT[@]}"; do
            [[ "$key" == "$s" ]] && match=1 && break
        done
        [[ $match -eq 0 ]] && continue
    fi
    pull_one "$key" "$uri"
done

echo
echo "Done. Use this directory with: setup_workflow.py --images-dir $(pwd)"
