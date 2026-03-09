# ====================================================================
# Compleasm
# ====================================================================
rule compleasm:
    input:
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        summary=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/summary_results.txt",
        hap1_summary=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/hp1/summary.txt",
        hap2_summary=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/hp2/summary.txt"
    params:
        sample="{sample}",
        assembler="{assembler}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}",
        library=config["tools"]["compleasm_library"]
    threads:
        get_threads("compleasm", 16)
    resources:
        mem_mb=get_mem_mb("compleasm", 128000)
    log:
        "logs/evaluation/compleasm/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("compleasm", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/compleasm/compleasm.sh \
            {params.sample} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {params.output_dir} \
            {threads} \
            {params.library} &> {log}

        python3 {SCRIPTS_DIR}/evaluation/compleasm/summary_compleasm_results.py \
            {params.sample} \
            {params.assembler} \
            1 \
            {output.hap1_summary} \
        > {output.summary}

        python3 {SCRIPTS_DIR}/evaluation/compleasm/summary_compleasm_results.py \
            {params.sample} \
            {params.assembler} \
            2 \
            {output.hap2_summary} \
        | awk '{{if (NR != 1) print}}' >> {output.summary}
        """
