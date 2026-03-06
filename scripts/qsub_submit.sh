#!/bin/bash
# Snakemake cluster submission script for UGE/SGE
# Usage: qsub_submit.sh <threads> <mem_mb> <snakemake_jobscript>
#
# Converts total memory (MB) to per-CPU memory (GB) for s_vmem
# Outputs only the job ID for snakemake to parse

THREADS=$1
MEM_MB=$2
shift 2  # remaining args are the job script

# Calculate per-CPU memory in GB (round up)
MEM_PER_CPU_GB=$(( (MEM_MB / THREADS + 1023) / 1024 ))

# Ensure minimum 1G
if [ "$MEM_PER_CPU_GB" -lt 1 ]; then
    MEM_PER_CPU_GB=1
fi

# Submit job with qsub and extract job ID
# -V: pass current environment (including apptainer/snakemake PATH) to compute nodes
OUTPUT=$(qsub -cwd -V -o log/ -e log/ \
    -l s_vmem=${MEM_PER_CPU_GB}G \
    -pe def_slot ${THREADS} \
    "$@" 2>&1)

# Extract job ID from qsub output
# Japanese: "ジョブ 12345 ("name") が投入されました"
# English:  "Your job 12345 ("name") has been submitted"
JOBID=$(echo "$OUTPUT" | grep -oP '(ジョブ|Your job|your job)\s+\K[0-9]+' | head -1)

if [ -n "$JOBID" ]; then
    echo "$JOBID"
else
    echo "Failed to parse job ID from: $OUTPUT" >&2
    exit 1
fi
