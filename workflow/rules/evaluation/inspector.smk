# ====================================================================
# Inspector (hifi)
# ====================================================================
rule inspector_hifi:
    input:
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        hifi_fastq=lambda wc: get_hifi_fastq(wc),
        reference=config["references"]["chm13"]
    output:
        summary=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/summary_results.txt",
        hap1_small=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp1/small_scale_error.bed",
        hap2_small=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp2/small_scale_error.bed",
        hap1_structural=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp1/structural_error.bed",
        hap2_structural=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp2/structural_error.bed"
    params:
        sample="{sample}",
        assembler="{assembler}",
        sex=lambda wc: get_sample_sex(wc),
        output_dir=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi"
    threads:
        get_threads("inspector", 16)
    resources:
        mem_mb=get_mem_mb("inspector", 128000)
    log:
        "logs/evaluation/inspector/{sample}/{assembler}/hifi.log"
    singularity:
        config.get("images", {}).get("inspector", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/inspector/inspector.sh \
            {params.sample} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {input.hifi_fastq} \
            {params.output_dir} \
            {threads} &> {log}

        python3 {SCRIPTS_DIR}/evaluation/inspector/summary_inspector_results.py \
            {params.sample} \
            {params.assembler} \
            1 \
            hifi \
            {params.output_dir}/hp1/summary_statistics \
            {params.output_dir}/hp1/structural_error.bed \
        > {output.summary}

        python3 {SCRIPTS_DIR}/evaluation/inspector/summary_inspector_results.py \
            {params.sample} \
            {params.assembler} \
            2 \
            hifi \
            {params.output_dir}/hp2/summary_statistics \
            {params.output_dir}/hp2/structural_error.bed \
        | tail -n +2 >> {output.summary}
        """
