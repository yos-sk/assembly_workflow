"""
RepeatMasker annotation
Identifies and classifies repetitive elements in assembly sequences
"""

# ====================================================================
# RepeatMasker annotation
# ====================================================================
rule repeatmasker:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa"
    output:
        rmsk_out=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.filt.fa.out",
        rmsk_bed_gz=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.rmsk.bed.gz",
        rmsk_bed_tbi=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.rmsk.bed.gz.tbi",
        simple_repeats_gz=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.simple_repeats.bed.gz",
        simple_repeats_tbi=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.simple_repeats.bed.gz.tbi",
        line1_gz=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.LINE1.bed.gz",
        line1_tbi=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.LINE1.bed.gz.tbi"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}"
    threads:
        get_threads("repeatmasker", 56)
    resources:
        mem_mb=get_mem_mb("repeatmasker", 448000)
    log:
        "logs/annotation/repeatmasker/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("repeatmasker", "")
    shell:
        """
        export BLASTDB_LMDB_MAP_SIZE=100000000
        /bin/bash {SCRIPTS_DIR}/annotation/RepeatMasker/RepeatMasker.sh \
            {params.sample} \
            {input.assembly} \
            {params.output_dir} \
            {SCRIPTS_DIR} \
            {threads} &> {log}
        """
