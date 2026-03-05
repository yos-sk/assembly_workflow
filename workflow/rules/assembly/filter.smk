"""
Filter assembly contigs
- Filter contigs by length (>100kb)
- Mask alpha satellite regions using DNA-NN
- Align to reference and filter based on alignment
- Reverse complement contigs to match reference orientation
- Generate assembly statistics
"""

# ====================================================================
# Filter assembly contigs
# ====================================================================
rule filter_assembly:
    input:
        hap1=lambda wildcards: get_raw_assembly_outputs(wildcards)["hap1"],
        hap2=lambda wildcards: get_raw_assembly_outputs(wildcards)["hap2"],
        reference=config["references"]["chm13"]
    output:
        hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        combined=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa",
        hap1_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa.fai",
        hap2_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa.fai",
        combined_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa.fai",
        hap1_ref_table=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.ref.table",
        hap2_ref_table=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.ref.table",
        hap1_stats=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1_stats.txt",
        hap2_stats=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2_stats.txt"
    params:
        sample="{sample}",
        sex=lambda wildcards: get_sample_sex(wildcards),
        dna_nn_model=config["tools"]["dna_nn_model"],
        output_dir=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/work"
    threads:
        get_threads("filter", 16)
    resources:
        mem_mb=get_mem_mb("filter", 128000)
    singularity:
        config.get("images", {}).get("filter_assembly", "")
    log:
        "logs/assembly/filter/{sample}/{assembler}.log"
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/assembly/filter/filter.sh \
            {input.hap1} \
            {input.hap2} \
            {input.reference} \
            {params.sample} \
            {params.sex} \
            {params.dna_nn_model} \
            {params.output_dir} \
            {threads} \
            {output.hap1} \
            {output.hap2} \
            {output.combined} \
            {output.hap1_stats} \
            {output.hap2_stats} \
            {SCRIPTS_DIR} &> {log}
        """
