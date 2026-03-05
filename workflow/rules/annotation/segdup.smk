"""
Segmental duplication annotation using sedef
Identifies and filters segmental duplications in assemblies
"""

# ====================================================================
# Sedef - Segmental duplication detection
# ====================================================================
rule sedef:
    input:
        hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        hap1_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa.fai",
        hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        hap2_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa.fai",
        repeatmasker=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.rmsk.bed.gz",
        trf=config["output"]["base"] + "/{sample}/annotation/trf_mod/{assembler}/{sample}.trf-mod.bed"
    output:
        hap1_final=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/HP1/final.bed",
        hap2_final=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/HP2/final.bed"
    params:
        work_dir=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/work",
        output_dir=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}",
        seqtk=config["tools"]["seqtk"],
        samtools=config["tools"]["samtools"]
    threads:
        get_threads("sedef", 14)
    resources:
        mem_mb=get_mem_mb("sedef", 112000)
    log:
        "logs/annotation/segdup/{sample}/{assembler}/sedef.log"
    singularity:
        config.get("images", {}).get("sedef", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/segdup/sedef.sh \
            {input.hap1} \
            {input.hap2} \
            {input.repeatmasker} \
            {input.trf} \
            {params.work_dir} \
            {params.output_dir} &> {log}
        """


# ====================================================================
# Filter sedef results
# Filters segmental duplications based on quality metrics
# ====================================================================
rule filter_sedef:
    input:
        hap1_sedef=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/HP1/final.bed",
        hap2_sedef=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/HP2/final.bed",
        repeatmasker=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.rmsk.bed.gz",
        hap1_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa.fai",
        hap2_fai=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa.fai"
    output:
        filtered_bed_gz=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/{sample}.filtered.bed.gz",
        filtered_bed_tbi=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/{sample}.filtered.bed.gz.tbi",
        summary=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/{sample}.segdup.len.summary.txt",
        hap1_segdup_gz=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/workspace/{sample}.hap1.segdup.sep.bed.gz",
        hap1_segdup_tbi=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/workspace/{sample}.hap1.segdup.sep.bed.gz.tbi",
        hap2_segdup_gz=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/workspace/{sample}.hap2.segdup.sep.bed.gz",
        hap2_segdup_tbi=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}/workspace/{sample}.hap2.segdup.sep.bed.gz.tbi"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/segdup/{assembler}",
        bgzip=config["tools"]["bgzip"],
        tabix=config["tools"]["tabix"]
    threads:
        get_threads("filter_sedef", 1)
    resources:
        mem_mb=get_mem_mb("filter_sedef", 10240)
    log:
        "logs/annotation/segdup/{sample}/{assembler}/filter_sedef.log"
    singularity:
        config.get("images", {}).get("sedef", "")
    shell:
        """
        # Uncompress repeatmasker bed for processing
        WORK_DIR={params.output_dir}/workspace
        mkdir -p $WORK_DIR

        zcat {input.repeatmasker} > $WORK_DIR/rmsk_hap1.bed
        zcat {input.repeatmasker} > $WORK_DIR/rmsk_hap2.bed

        /bin/bash {SCRIPTS_DIR}/annotation/segdup/filter_sedef.sh \
            {params.sample} \
            {input.hap1_sedef} \
            {input.hap2_sedef} \
            {params.output_dir} \
            $WORK_DIR/rmsk_hap1.bed \
            $WORK_DIR/rmsk_hap2.bed \
            {input.hap1_fai} \
            {input.hap2_fai} \
            {SCRIPTS_DIR} &> {log}

        # Clean up temporary files
        rm -f $WORK_DIR/rmsk_hap1.bed $WORK_DIR/rmsk_hap2.bed
        """
