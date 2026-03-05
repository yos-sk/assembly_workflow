"""
Liftoff gene annotation
Lifts over gene annotations from GRCh38 to assembly
"""

# ====================================================================
# Liftoff annotation
# ====================================================================
rule liftoff:
    input:
        hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        grch38=config["references"]["grch38"],
        grch38_gtf=config["references"]["grch38_gtf"]
    output:
        bed_gz=config["output"]["base"] + "/{sample}/annotation/liftoff/{assembler}/{sample}.Ensembl_GRCh38.liftoff.bed.gz",
        bed_tbi=config["output"]["base"] + "/{sample}/annotation/liftoff/{assembler}/{sample}.Ensembl_GRCh38.liftoff.bed.gz.tbi",
        gff_gz=config["output"]["base"] + "/{sample}/annotation/liftoff/{assembler}/{sample}.Ensembl_GRCh38.liftoff.gff.gz",
        gff_tbi=config["output"]["base"] + "/{sample}/annotation/liftoff/{assembler}/{sample}.Ensembl_GRCh38.liftoff.gff.gz.tbi",
        gtf_gz=config["output"]["base"] + "/{sample}/annotation/liftoff/{assembler}/{sample}.Ensembl_GRCh38.liftoff.gtf.gz"
    params:
        sample="{sample}",
        assembler="{assembler}",
        sex=lambda wildcards: get_sample_sex(wildcards),
        output_dir=config["output"]["base"] + "/{sample}/annotation/liftoff/{assembler}",
        bgzip=config["tools"]["bgzip"],
        tabix=config["tools"]["tabix"]
    threads:
        get_threads("liftoff", 50)
    resources:
        mem_mb=get_mem_mb("liftoff", 400000)
    log:
        "logs/annotation/liftoff/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("liftoff", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/liftoff/liftoff.sh \
            {params.sample} \
            {params.assembler} \
            {input.hap1} \
            {input.hap2} \
            {params.sex} \
            {input.grch38} \
            {input.grch38_gtf} \
            {params.output_dir} \
            {threads} &> {log}
        """
