#!/bin/bash
# Check job status for snakemake cluster-generic executor
# Usage: qsub_status.sh <jobid>
# Returns: running, success, or failed

JOBID=$1

# Check if job is still in queue
STATE=$(qstat -j "$JOBID" 2>/dev/null | grep "^job_state" | awk '{print $2}')

if [ -n "$STATE" ]; then
    # Job is in the queue (running or waiting)
    echo "running"
else
    # Job finished - check accounting for exit status
    EXIT_STATUS=$(qacct -j "$JOBID" 2>/dev/null | grep "^exit_status" | tail -1 | awk '{print $2}')
    if [ -z "$EXIT_STATUS" ]; then
        # qacct may not be available yet, assume running
        echo "running"
    elif [ "$EXIT_STATUS" = "0" ]; then
        echo "success"
    else
        echo "failed"
    fi
fi
