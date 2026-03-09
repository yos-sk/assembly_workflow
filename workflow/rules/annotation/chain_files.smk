"""
Chain file generation for liftover between assemblies and references
Creates chain files for coordinate conversion between:
- Assembly to CHM13/GRCh38
- CHM13/GRCh38 to Assembly
"""

# ====================================================================
# Prepare masked reference genomes
# This rule creates masked versions of reference genomes with
# centromeres and false duplications masked
# ====================================================================
rule prepare_mask_regions:
    input:
        chm13=config["references"]["chm13"],
        chm13_satellite=config["references"]["chm13_satellite"],
        grch38=config["references"]["grch38"],
        grch38_centromeres=config["references"]["grch38_centromeres"],
        grch38_exclusions=config["references"]["grch38_exclusions"]
    output:
        chm13_masked="db/references/chm13.masked.fa",
        chm13_masked_fai="db/references/chm13.masked.fa.fai",
        chm13_masked_noY="db/references/chm13.masked_noY.fa",
        chm13_masked_noY_fai="db/references/chm13.masked_noY.fa.fai",
        grch38_masked="db/references/GRCh38.masked.fa",
        grch38_masked_fai="db/references/GRCh38.masked.fa.fai",
        grch38_masked_noY="db/references/GRCh38.masked_noY.fa",
        grch38_masked_noY_fai="db/references/GRCh38.masked_noY.fa.fai"
    params:
        output_dir="db/references",
        work_dir="db/references/work",
    threads:
        get_threads("chain_files", 1)
    resources:
        mem_mb=get_mem_mb("chain_files", 10240)
    log:
        "logs/annotation/chain_files/prepare_mask_regions.log"
    singularity:
        config.get("images", {}).get("chain_files", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/chain-files/prepare_mask_regions.sh \
            {input.chm13_satellite} \
            {input.chm13} \
            {input.grch38_centromeres} \
            {input.grch38_exclusions} \
            {input.grch38} \
            {params.output_dir} \
            {params.work_dir} \
            {SCRIPTS_DIR}/annotation &> {log}
        """


# ====================================================================
# Create chain files for liftover
# Creates bidirectional chain files between assembly and references
# ====================================================================
rule make_chain_files:
    input:
        hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        # Masked reference genomes
        chm13_masked="db/references/chm13.masked.fa",
        chm13_masked_noY="db/references/chm13.masked_noY.fa",
        grch38_masked="db/references/GRCh38.masked.fa",
        grch38_masked_noY="db/references/GRCh38.masked_noY.fa"
    output:
        sample_to_chm13=config["output"]["base"] + "/{sample}/annotation/chain_files/{assembler}/{sample}_to_chm13.chain",
        sample_to_grch38=config["output"]["base"] + "/{sample}/annotation/chain_files/{assembler}/{sample}_to_GRCh38.chain",
        chm13_to_sample=config["output"]["base"] + "/{sample}/annotation/chain_files/{assembler}/chm13_to_{sample}.chain",
        grch38_to_sample=config["output"]["base"] + "/{sample}/annotation/chain_files/{assembler}/GRCh38_to_{sample}.chain"
    params:
        sample="{sample}",
        assembler="{assembler}",
        sex=lambda wildcards: get_sample_sex(wildcards),
        reference_dir="db/references",
        work_dir=config["output"]["base"] + "/{sample}/annotation/chain_files/{assembler}/work",
        output_dir=config["output"]["base"] + "/{sample}/annotation/chain_files/{assembler}"
    threads:
        get_threads("chain_files", 16)
    resources:
        mem_mb=get_mem_mb("chain_files", 128000)
    log:
        "logs/annotation/chain_files/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("chain_files", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/chain-files/make_chain_files.sh \
            {params.sample} \
            {input.hap1} \
            {input.hap2} \
            {params.assembler} \
            {params.sex} \
            {params.reference_dir} \
            {params.work_dir} \
            {params.output_dir} &> {log}
        """
