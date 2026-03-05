"""
Alignment of reads to assemblies
Generates BAM files used by Flagger and NucFlag for error detection
Uses get_hifi_fastq/get_ont_fastq from bam_to_fastq.smk to support both BAM and FASTQ inputs
"""

# ====================================================================
# HiFi read alignment
# ====================================================================
rule alignment_hifi:
    input:
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        hifi_fastq=lambda wc: get_hifi_fastq(wc)
    output:
        bam=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi/{sample}_hifi.bam",
        bai=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi/{sample}_hifi.bam.bai"
    params:
        sample="{sample}",
        assembler="{assembler}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi"
    threads:
        get_threads("alignment_hifi", 16)
    resources:
        mem_mb=get_mem_mb("alignment_hifi", 128000)
    log:
        "logs/evaluation/alignment/{sample}/{assembler}/hifi.log"
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/alignment/alignment.sh \
            {params.sample} \
            {params.assembler} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {input.hifi_fastq} \
            {params.output_dir} \
            hifi \
            {threads} &> {log}
        """


# ====================================================================
# ONT read alignment
# ====================================================================
rule alignment_ont:
    input:
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        ont_fastq=lambda wc: get_ont_fastq(wc)
    output:
        bam=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/ont/{sample}_ont.bam",
        bai=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/ont/{sample}_ont.bam.bai"
    params:
        sample="{sample}",
        assembler="{assembler}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/ont"
    threads:
        get_threads("alignment_ont", 16)
    resources:
        mem_mb=get_mem_mb("alignment_ont", 128000)
    log:
        "logs/evaluation/alignment/{sample}/{assembler}/ont.log"
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/alignment/alignment.sh \
            {params.sample} \
            {params.assembler} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {input.ont_fastq} \
            {params.output_dir} \
            ont \
            {threads} &> {log}
        """
