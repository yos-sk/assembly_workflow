"""
DNA-NN (DNA-BRNN) annotation
Identifies alpha satellite regions using deep neural networks
"""

# ====================================================================
# DNA-NN alpha satellite annotation
# ====================================================================
rule dna_nn:
    input:
        hap1=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        hap2=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa"
    output:
        hap1_bed_gz=config["output"]["base"] + "/{sample}/annotation/dna_nn/{assembler}/{sample}.hap1_dna-brnn.bed.gz",
        hap1_bed_tbi=config["output"]["base"] + "/{sample}/annotation/dna_nn/{assembler}/{sample}.hap1_dna-brnn.bed.gz.tbi",
        hap2_bed_gz=config["output"]["base"] + "/{sample}/annotation/dna_nn/{assembler}/{sample}.hap2_dna-brnn.bed.gz",
        hap2_bed_tbi=config["output"]["base"] + "/{sample}/annotation/dna_nn/{assembler}/{sample}.hap2_dna-brnn.bed.gz.tbi"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/dna_nn/{assembler}",
    threads:
        get_threads("dna_nn", 16)
    resources:
        mem_mb=get_mem_mb("dna_nn", 80000)
    log:
        "logs/annotation/dna_nn/{sample}/{assembler}.log"
    singularity:
        config.get("images", {}).get("dna_nn", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/dna-nn/dna-nn.sh \
            {params.sample} \
            {input.hap1} \
            {input.hap2} \
            {params.output_dir} &> {log}
        """
