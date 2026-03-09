# ====================================================================
# Yak
# ====================================================================
rule yak_count:
    input:
        hifi_fastq=lambda wc: get_hifi_fastq(wc)
    output:
        yak=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}/{sample}.pb.yak"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}"
    threads:
        get_threads("yak", 32)
    resources:
        mem_mb=get_mem_mb("yak", 256000)
    log:
        "logs/evaluation/yak/{sample}/{assembler}/yak_count.log"
    singularity:
        config.get("images", {}).get("yak", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/yak/yak_count.sh \
            {input.hifi_fastq} \
            {params.output_dir} \
            {params.sample} \
            {threads} &> {log}
        """

rule yak_qv:
    input:
        yak=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}/{sample}.pb.yak",
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        hap1_qv=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}/{sample}.hap1.pb.yak.qv.txt",
        hap2_qv=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}/{sample}.hap2.pb.yak.qv.txt"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}"
    threads:
        get_threads("yak", 32)
    resources:
        mem_mb=get_mem_mb("yak", 256000)
    log:
        "logs/evaluation/yak/{sample}/{assembler}/yak_qv.log"
    singularity:
        config.get("images", {}).get("yak", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/yak/yak_qv.sh \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {input.yak} \
            {params.output_dir} \
            {params.sample} \
            {threads} &> {log}
        """
