# ====================================================================
# Count T2T contigs
# ====================================================================
rule t2t_count:
    input:
        assembly_hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        reference=config["references"]["chm13"]
    output:
        hap1_t2t=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}/t2t_contigs_hap1.txt",
        hap2_t2t=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}/t2t_contigs_hap2.txt"
    params:
        sample="{sample}",
        sex=lambda wc: get_sample_sex(wc),
        output_dir=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}"
    threads:
        get_threads("t2t", 1)
    resources:
        mem_mb=get_mem_mb("t2t", 30000)
    log:
        "logs/evaluation/t2t/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("mashmap", "")
    shell:
        """
        mkdir -p {params.output_dir}
        /bin/bash {SCRIPTS_DIR}/evaluation/t2t/t2t_count.sh \
            {input.assembly_hap1} \
            {input.assembly_hap2} \
            {input.reference} \
            {params.output_dir} \
            {params.sex} &> {log}

        python3 {SCRIPTS_DIR}/evaluation/t2t/count_t2t.py \
            {params.output_dir}/telo_hap1.tsv \
            {params.output_dir}/APPROX-ALIGN_hap1.paf \
        > {output.hap1_t2t}

        python3 {SCRIPTS_DIR}/evaluation/t2t/count_t2t.py \
            {params.output_dir}/telo_hap2.tsv \
            {params.output_dir}/APPROX-ALIGN_hap2.paf \
        > {output.hap2_t2t}
        """
