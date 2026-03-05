# ====================================================================
# Haplotype switch
# ====================================================================

# Rule 1: PSTools - phasing error detection using Hi-C reads
rule pstools:
    input:
        hap1_assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        hap2_assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        hic_r1=lambda wc: samples.loc[wc.sample, "hic_r1"] if "hic_r1" in samples.columns else "",
        hic_r2=lambda wc: samples.loc[wc.sample, "hic_r2"] if "hic_r2" in samples.columns else ""
    output:
        phase_error=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/pstools/phase_error_output.txt",
        hic_connection=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/pstools/hic_connection_in_haps.txt"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/pstools"
    threads:
        get_threads("pstools", 56)
    resources:
        mem_mb=get_mem_mb("pstools", 448000)
    log:
        "logs/evaluation/haplotype_switch/{sample}/{assembler}/pstools.log"
    singularity:
        config.get("images", {}).get("pstools", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/haplotype_switch/pstools.sh \
            {input.hap1_assembly} \
            {input.hap2_assembly} \
            {input.hic_r1} \
            {input.hic_r2} \
            {params.output_dir} &> {log}
        """


# Rule 2: Yak trioeval - haplotype phasing assessment using parental reads
rule yak_trioeval:
    input:
        pat_r1=lambda wc: samples.loc[wc.sample, "pat_r1"] if "pat_r1" in samples.columns else "",
        pat_r2=lambda wc: samples.loc[wc.sample, "pat_r2"] if "pat_r2" in samples.columns else "",
        mat_r1=lambda wc: samples.loc[wc.sample, "mat_r1"] if "mat_r1" in samples.columns else "",
        mat_r2=lambda wc: samples.loc[wc.sample, "mat_r2"] if "mat_r2" in samples.columns else "",
        assembly_pat=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        assembly_mat=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        pat_yak=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/yak_trioeval/pat.yak",
        mat_yak=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/yak_trioeval/mat.yak",
        paternal_phasing=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/yak_trioeval/paternal.yak_phasing.txt",
        maternal_phasing=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/yak_trioeval/maternal.yak_phasing.txt"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/haplotype_switch/{assembler}/yak_trioeval"
    threads:
        get_threads("yak_trioeval", 32)
    resources:
        mem_mb=get_mem_mb("yak_trioeval", 256000)
    log:
        "logs/evaluation/haplotype_switch/{sample}/{assembler}/yak_trioeval.log"
    singularity:
        config.get("images", {}).get("yak", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/haplotype_switch/yak_trioeval.sh \
            {input.pat_r1} \
            {input.pat_r2} \
            {input.mat_r1} \
            {input.mat_r2} \
            {input.assembly_pat} \
            {input.assembly_mat} \
            {params.output_dir} &> {log}
        """
