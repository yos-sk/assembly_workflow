"""
CenSat annotation workflow
Annotates centromeric and satellite regions in assemblies
"""

# ====================================================================
# Step 0: Split FASTA for parallel processing
# ====================================================================
rule censat_split_fasta:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa"
    output:
        split_done=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work/split/.done"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work"
    threads:
        get_threads("censat_split", 1)
    resources:
        mem_mb=get_mem_mb("censat_split", 30720)
    log:
        "logs/annotation/censat/{sample}/{assembler}/split_fasta.log"
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/censat/split_fasta.sh \
            {input.assembly} \
            {params.work_dir} &> {log}
        touch {output.split_done}
        """


# ====================================================================
# Step 1a: AlphaSat HMMER annotation
# ====================================================================
rule censat_alphasat:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa",
        split_done=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work/split/.done"
    output:
        hor_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/hor.bed",
        sf_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/sf.bed",
        strand_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/strand.bed"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work"
    threads:
        get_threads("censat_alphasat", 56)
    resources:
        mem_mb=get_mem_mb("censat_alphasat", 448000)
    log:
        "logs/annotation/censat/{sample}/{assembler}/alphasat.log"
    singularity:
        config.get("images", {}).get("censat_alphasat", "")
    shell:
        """
        cd {SCRIPTS_DIR}/annotation/censat && \
        /bin/bash alphaSat_HMMER.sh \
            {input.assembly} \
            {params.output_dir} &> {log}
        """


# ====================================================================
# Step 1a-2: Create alphaSat BED
# ====================================================================
rule censat_create_asat_bed:
    input:
        hor_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/hor.bed",
        sf_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/sf.bed"
    output:
        summary_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/summary_alphaSat.bed"
    params:
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work/alphaSat"
    threads:
        get_threads("censat_create_asat_bed", 1)
    resources:
        mem_mb=get_mem_mb("censat_create_asat_bed", 30720)
    log:
        "logs/annotation/censat/{sample}/{assembler}/create_asat_bed.log"
    singularity:
        config.get("images", {}).get("censat_alphasat", "")
    shell:
        """
        cd {SCRIPTS_DIR}/annotation/censat && \
        /bin/bash create_asat_bed.sh \
            {input.hor_bed} \
            {input.sf_bed} \
            {output.summary_bed} \
            {params.work_dir} &> {log}
        """


# ====================================================================
# Step 1b: rDNA annotation
# ====================================================================
rule censat_rdna:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa",
        split_done=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work/split/.done"
    output:
        rdna_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/rDNA.bed"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work"
    threads:
        get_threads("censat_rdna", 24)
    resources:
        mem_mb=get_mem_mb("censat_rdna", 192000)
    log:
        "logs/annotation/censat/{sample}/{assembler}/rdna.log"
    singularity:
        config.get("images", {}).get("censat_hmmer", "")
    shell:
        """
        cd {SCRIPTS_DIR}/annotation/censat && \
        /bin/bash rDNA_annotation.sh \
            {input.assembly} \
            {params.output_dir} &> {log}
        """


# ====================================================================
# Step 1c: Gap annotation
# ====================================================================
rule censat_gaps:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa"
    output:
        gaps_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/gaps.filtered.bed"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work"
    threads:
        get_threads("censat_gaps", 1)
    resources:
        mem_mb=get_mem_mb("censat_gaps", 30720)
    log:
        "logs/annotation/censat/{sample}/{assembler}/gaps.log"
    singularity:
        config.get("images", {}).get("censat_tools", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/censat/gap_annotation.sh \
            {input.assembly} \
            {params.output_dir} &> {log}
        """


# ====================================================================
# Step 1d: HSat2 and HSat3 annotation
# ====================================================================
rule censat_hsat:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa"
    output:
        hsat_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/HSat2and3_Regions.bed"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work"
    threads:
        get_threads("censat_hsat", 1)
    resources:
        mem_mb=get_mem_mb("censat_hsat", 30720)
    log:
        "logs/annotation/censat/{sample}/{assembler}/hsat.log"
    singularity:
        config.get("images", {}).get("censat_hsat", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/censat/identity-hSat2and3.sh \
            {input.assembly} \
            {params.output_dir} \
            {SCRIPTS_DIR}/annotation/censat &> {log}
        """


# ====================================================================
# Step 1e: RepeatMasker output processing
# ====================================================================
rule censat_repeatmasker:
    input:
        rmsk_out=config["output"]["base"] + "/{sample}/annotation/repeatmasker/{assembler}/{sample}.filt.fa.out"
    output:
        rmsk_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}_rm.bed"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}"
    threads:
        get_threads("censat_repeatmasker", 1)
    resources:
        mem_mb=get_mem_mb("censat_repeatmasker", 30720)
    log:
        "logs/annotation/censat/{sample}/{assembler}/repeatmasker.log"
    singularity:
        config.get("images", {}).get("censat_rm2bed", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/censat/repeatmasker.sh \
            {input.rmsk_out} \
            {params.output_dir} \
            {params.sample} &> {log}
        """


# ====================================================================
# Step 2: Create final annotations
# ====================================================================
rule censat_create_annotations:
    input:
        rmsk_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}_rm.bed",
        alphasat_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/summary_alphaSat.bed",
        strand_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/strand.bed",
        hsat_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/HSat2and3_Regions.bed",
        rdna_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/rDNA.bed",
        gaps_bed=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/gaps.filtered.bed"
    output:
        resolved_overlaps_gz=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.sorted.resolved_overlaps.bed.gz",
        resolved_overlaps_tbi=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.sorted.resolved_overlaps.bed.gz.tbi",
        censat_gz=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.cenSat.bed.gz",
        censat_tbi=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.cenSat.bed.gz.tbi",
        strand_gz=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.SatelliteStrand.bed.gz",
        strand_tbi=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.SatelliteStrand.bed.gz.tbi",
        centromeres_gz=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.active.centromeres.bed.gz",
        centromeres_tbi=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/{sample}.active.centromeres.bed.gz.tbi"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/annotation/censat/{assembler}/work/annotation"
    threads:
        get_threads("censat_create", 1)
    resources:
        mem_mb=get_mem_mb("censat_create", 30720)
    log:
        "logs/annotation/censat/{sample}/{assembler}/create_annotations.log"
    singularity:
        config.get("images", {}).get("censat_tools", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/censat/run_create_annotation.sh \
            {params.output_dir} \
            {params.sample} \
            {input.rmsk_bed} \
            {input.alphasat_bed} \
            {input.strand_bed} \
            {input.hsat_bed} \
            {input.rdna_bed} \
            {input.gaps_bed} \
            {SCRIPTS_DIR} &> {log}
        """
