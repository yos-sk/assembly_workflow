"""
Assembly, annotation, and evaluation workflow rules
This file imports rules from assembly, annotation, and evaluation modules.
"""

import os

SCRIPTS_DIR = os.path.join(workflow.basedir, "scripts")

# ====================================================================
# Import reads processing rules (BAM to FASTQ conversion)
# ====================================================================
include: "reads/bam_to_fastq.smk"


# ====================================================================
# Import assembly rules
# ====================================================================
include: "assembly/assembly.smk"
include: "assembly/filter.smk"


# ====================================================================
# Import annotation rules
# ====================================================================
include: "annotation/trf_mod.smk"
include: "annotation/dna_nn.smk"
include: "annotation/repeatmasker.smk"
include: "annotation/chain_files.smk"
include: "annotation/liftoff.smk"
include: "annotation/segdup.smk"
include: "annotation/censat.smk"


# ====================================================================
# Import evaluation rules
# ====================================================================
include: "evaluation/alignment.smk"
include: "evaluation/compleasm.smk"
include: "evaluation/count_t2t.smk"
include: "evaluation/flagger.smk"
include: "evaluation/haplotype_switch.smk"
include: "evaluation/inspector.smk"
include: "evaluation/merge_results.smk"
include: "evaluation/merqury.smk"
include: "evaluation/nucflag.smk"
include: "evaluation/yak.smk"
