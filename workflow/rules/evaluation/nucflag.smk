"""
NucFlag nucleotide-level error detection
Detects misassemblies using read alignment patterns
Requires aligned BAM files from alignment rules
"""

# ====================================================================
# NucFlag with HiFi reads
# ====================================================================
rule nucflag:
    input:
        hifi_bam=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi/{sample}_hifi.bam",
        hifi_bai=config["output"]["base"] + "/{sample}/evaluation/alignment/{assembler}/hifi/{sample}_hifi.bam.bai"
    output:
        misassembly=config["output"]["base"] + "/{sample}/evaluation/nucflag/{assembler}/nucflag_misassembly.txt",
        summary=config["output"]["base"] + "/{sample}/evaluation/nucflag/{assembler}/summary_results.txt"
    params:
        sample="{sample}",
        assembler="{assembler}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/nucflag/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/evaluation/nucflag/{assembler}/workspace"
    threads:
        get_threads("nucflag", 16)
    resources:
        mem_mb=get_mem_mb("nucflag", 128000)
    log:
        "logs/evaluation/nucflag/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("nucflag", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/nucflag/nucflag.sh \
            {input.hifi_bam} \
            {params.output_dir} \
            {params.work_dir} \
            {threads} &> {log}

        python3 {SCRIPTS_DIR}/evaluation/nucflag/summary_nucflag_results.py \
            {params.sample} \
            {params.assembler} \
            {output.misassembly} \
        > {output.summary}
        """