# ====================================================================
# Merqury
# ====================================================================
rule merqury:
    input:
        illumina_r1=lambda wildcards: samples.loc[wildcards.sample, "illumina_r1"],
        illumina_r2=lambda wildcards: samples.loc[wildcards.sample, "illumina_r2"],
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        qv=config["output"]["base"] + "/{sample}/evaluation/merqury/{assembler}/out.qv"
    params:
        db_dir=config["output"]["base"] + "/{sample}/evaluation/merqury/{assembler}/db",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/merqury/{assembler}"
    threads:
        get_threads("merqury", 8)
    resources:
        mem_mb=get_mem_mb("merqury", 256000)
    log:
        "logs/evaluation/merqury/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("merqury", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/merqury/merqury.sh \
            {input.illumina_r1} \
            {input.illumina_r2} \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {params.db_dir} \
            {params.output_dir} \
            {threads} \
            {resources.mem_mb} &> {log}
        """
