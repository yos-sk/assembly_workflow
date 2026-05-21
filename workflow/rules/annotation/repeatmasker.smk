"""
RepeatMasker annotation
Identifies and classifies repetitive elements in assembly sequences
Split into per-haplotype processing to reduce memory usage during merge
"""

# ====================================================================
# RepeatMasker per-haplotype
# ====================================================================
rule repeatmasker_hap:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.{hap}.filt.fa"
    output:
        rmsk_out=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.{hap}.filt.fa.out"
    wildcard_constraints:
        hap="hap[12]"
    params:
        output_dir=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}",
        # Drop snakemake's auto-wrapping and invoke singularity manually so
        # we can add --net --network=none for this rule only.
        singularity_cmd=get_repeatmasker_singularity_cmd()
    threads:
        get_threads("repeatmasker", 56)
    resources:
        mem_mb=get_mem_mb("repeatmasker", 448000)
    log:
        "logs/annotation/repeatmasker/{sample}/{assembler}/{hap}.log"
    shell:
        """
        {params.singularity_cmd} \
            bash {SCRIPTS_DIR}/annotation/RepeatMasker/RepeatMasker_hap.sh \
            {input.assembly} \
            {params.output_dir} \
            {threads} &> {log}
        """


# ====================================================================
# Merge per-haplotype RepeatMasker results
# ====================================================================
rule repeatmasker_merge:
    input:
        hap1_out=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.hap1.filt.fa.out",
        hap2_out=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.hap2.filt.fa.out"
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
    threads: 1
    resources:
        mem_mb=30720
    log:
        "logs/annotation/repeatmasker/{sample}/{assembler}/merge.log"
    singularity:
        config.get("images", {}).get("dna_nn", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/RepeatMasker/RepeatMasker_merge.sh \
            {params.sample} \
            {input.hap1_out} \
            {input.hap2_out} \
            {params.output_dir} \
            {SCRIPTS_DIR} &> {log}
        """
