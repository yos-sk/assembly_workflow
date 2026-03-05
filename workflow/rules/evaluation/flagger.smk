"""
Flagger error detection
Uses read coverage and k-mer analysis to detect assembly errors
Requires aligned BAM files from alignment rules
"""

# ====================================================================
# Flagger with HiFi reads
# ====================================================================
rule flagger_hifi:
    input:
        hifi_bam=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi/{sample}_hifi.bam",
        hifi_bai=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi/{sample}_hifi.bam.bai",
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        prediction=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/hifi/final_flagger_prediction.bed",
        summary=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/hifi/summary_flagger_results.txt"
    params:
        sample="{sample}",
        assembler="{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/hifi/workspace",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/hifi"
    threads:
        get_threads("flagger", 16)
    resources:
        mem_mb=get_mem_mb("flagger", 128000)
    log:
        "logs/evaluation/flagger/{sample}/{assembler}/hifi.log"
    singularity:
        config.get("images", {}).get("flagger", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/flagger/flagger.sh \
            {input.hifi_bam} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {params.work_dir} \
            {params.output_dir} \
            hifi \
            {threads} &> {log}

        # Generate summary if script exists
        if [ -f {SCRIPTS_DIR}/evaluation/flagger/summary_flagger_results.py ]; then
            python3 {SCRIPTS_DIR}/evaluation/flagger/summary_flagger_results.py \
                {params.sample} \
                {params.assembler} \
                {output.prediction} \
            > {output.summary}
        fi
        """


# ====================================================================
# Flagger with ONT reads
# ====================================================================
rule flagger_ont:
    input:
        ont_bam=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/ont/{sample}_ont.bam",
        ont_bai=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/ont/{sample}_ont.bam.bai",
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        prediction=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/ont/final_flagger_prediction.bed",
        summary=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/ont/summary_flagger_results.txt"
    params:
        sample="{sample}",
        assembler="{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/ont/workspace",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/ont",
        ont_platform=lambda wc: samples.loc[wc.sample, "ont_platform"].lower() if "ont_platform" in samples.columns and pd.notna(samples.loc[wc.sample, "ont_platform"]) else "ont-r10"
    threads:
        get_threads("flagger", 16)
    resources:
        mem_mb=get_mem_mb("flagger", 128000)
    log:
        "logs/evaluation/flagger/{sample}/{assembler}/ont.log"
    singularity:
        config.get("images", {}).get("flagger", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/flagger/flagger.sh \
            {input.ont_bam} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {params.work_dir} \
            {params.output_dir} \
            {params.ont_platform} \
            {threads} &> {log}

        # Generate summary if script exists
        if [ -f {SCRIPTS_DIR}/evaluation/flagger/summary_flagger_results.py ]; then
            python3 {SCRIPTS_DIR}/evaluation/flagger/summary_flagger_results.py \
                {params.sample} \
                {params.assembler} \
                {output.prediction} \
            > {output.summary}
        fi
        """