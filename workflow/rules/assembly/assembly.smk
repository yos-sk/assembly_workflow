"""
Assembly workflow rules for different assemblers and modes
Supports:
- Hifiasm with Hi-C phasing
- Hifiasm with trio-binning
- Verkko with Hi-C phasing
- Verkko with Pore-C phasing
- Verkko with trio-binning
"""

# ====================================================================
# Hifiasm with Hi-C phasing
# ====================================================================
rule hifiasm_hic:
    input:
        ont_fastq=lambda wc: samples.loc[wc.sample, "ont_fastq"],
        hifi_fastq=lambda wc: samples.loc[wc.sample, "hifi_fastq"],
        hic_r1=lambda wc: samples.loc[wc.sample, "hic_r1"],
        hic_r2=lambda wc: samples.loc[wc.sample, "hic_r2"]
    output:
        primary=config["output"]["base"] + "/{sample}/assembly/hifiasm_hic/{sample}.fa",
        hap1=config["output"]["base"] + "/{sample}/assembly/hifiasm_hic/{sample}.hap1.fa",
        hap2=config["output"]["base"] + "/{sample}/assembly/hifiasm_hic/{sample}.hap2.fa"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/assembly/hifiasm_hic"
    threads: 
        get_threads("hifiasm_hic", 56)
    resources:
        mem_mb=get_mem_mb("hifiasm_hic", 448000)
    log:
        "logs/assembly/hifiasm_hic/{sample}.log"
    singularity:
        config.get("images", {}).get("hifiasm", "")
    shell:
        """
        /bin/bash workflow/scripts/assembly/hifiasm_hic.sh \
            {params.sample} \
            {input.ont_fastq} \
            {input.hifi_fastq} \
            {input.hic_r1} \
            {input.hic_r2} \
            {params.output_dir} \
            {threads} &> {log}
        """


# ====================================================================
# Hifiasm with trio-binning
# ====================================================================
rule hifiasm_trio:
    input:
        ont_fastq=lambda wc: samples.loc[wc.sample, "ont_fastq"],
        hifi_fastq=lambda wc: samples.loc[wc.sample, "hifi_fastq"],
        pat_r1=lambda wc: samples.loc[wc.sample, "pat_r1"],
        pat_r2=lambda wc: samples.loc[wc.sample, "pat_r2"],
        mat_r1=lambda wc: samples.loc[wc.sample, "mat_r1"],
        mat_r2=lambda wc: samples.loc[wc.sample, "mat_r2"]
    output:
        primary=config["output"]["base"] + "/{sample}/assembly/hifiasm_trio/{sample}.fa",
        hap1=config["output"]["base"] + "/{sample}/assembly/hifiasm_trio/{sample}.hap1.fa",
        hap2=config["output"]["base"] + "/{sample}/assembly/hifiasm_trio/{sample}.hap2.fa"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/assembly/hifiasm_trio"
    threads:
        get_threads("hifiasm_trio", 56)
    resources:
        mem_mb=get_mem_mb("hifiasm_trio", 448000)
    log:
        "logs/assembly/hifiasm_trio/{sample}.log"
    singularity:
        config.get("images", {}).get("hifiasm", "")
    shell:
        """
        /bin/bash workflow/scripts/assembly/hifiasm_trio.sh \
            {params.sample} \
            {input.ont_fastq} \
            {input.hifi_fastq} \
            {input.pat_r1} \
            {input.pat_r2} \
            {input.mat_r1} \
            {input.mat_r2} \
            {params.output_dir} &> {log}
        """


# ====================================================================
# Verkko with Pore-C phasing
# ====================================================================
rule verkko_porec:
    input:
        hifi_fastq=lambda wc: samples.loc[wc.sample, "hifi_fastq"],
        ont_fastq=lambda wc: samples.loc[wc.sample, "ont_fastq"],
        porec_fastq=lambda wc: samples.loc[wc.sample, "porec_fastq"]
    output:
        hap1=config["output"]["base"] + "/{sample}/assembly/verkko_porec/assembly/assembly.haplotype1.fasta",
        hap2=config["output"]["base"] + "/{sample}/assembly/verkko_porec/assembly/assembly.haplotype2.fasta",
        primary=config["output"]["base"] + "/{sample}/assembly/verkko_porec/assembly/assembly.fasta"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/assembly/verkko_porec"
    threads:
        get_threads("verkko_porec", 16)
    resources:
        mem_mb=get_mem_mb("verkko_porec", 480000)
    log:
        "logs/assembly/verkko_porec/{sample}.log"
    singularity:
        config.get("images", {}).get("verkko", "")
    shell:
        """
        /bin/bash workflow/scripts/assembly/verkko_porec.sh \
            {params.output_dir} \
            {input.hifi_fastq} \
            {input.ont_fastq} \
            {input.porec_fastq} &> {log}
        """


# ====================================================================
# Verkko with Hi-C phasing
# ====================================================================
rule verkko_hic:
    input:
        ont_fastq=lambda wc: samples.loc[wc.sample, "ont_fastq"],
        hifi_fastq=lambda wc: samples.loc[wc.sample, "hifi_fastq"],
        hic_r1=lambda wc: samples.loc[wc.sample, "hic_r1"],
        hic_r2=lambda wc: samples.loc[wc.sample, "hic_r2"]
    output:
        hap1=config["output"]["base"] + "/{sample}/assembly/verkko_hic/assembly/assembly.haplotype1.fasta",
        hap2=config["output"]["base"] + "/{sample}/assembly/verkko_hic/assembly/assembly.haplotype2.fasta",
        primary=config["output"]["base"] + "/{sample}/assembly/verkko_hic/assembly/assembly.fasta"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/assembly/verkko_hic"
    threads:
        get_threads("verkko_hic", 16)
    resources:
        mem_mb=get_mem_mb("verkko_hic", 480000)
    log:
        "logs/assembly/verkko_hic/{sample}.log"
    singularity:
        config.get("images", {}).get("verkko", "")
    shell:
        """
        /bin/bash workflow/scripts/assembly/verkko_hic.sh \
            {params.output_dir} \
            {input.ont_fastq} \
            {input.hifi_fastq} \
            {input.hic_r1} \
            {input.hic_r2} &> {log}
        """


# ====================================================================
# Verkko trio-binning preparation (k-mer counting)
# ====================================================================
rule verkko_trio_prep:
    input:
        pat_r1=lambda wc: samples.loc[wc.sample, "pat_r1"],
        pat_r2=lambda wc: samples.loc[wc.sample, "pat_r2"],
        mat_r1=lambda wc: samples.loc[wc.sample, "mat_r1"],
        mat_r2=lambda wc: samples.loc[wc.sample, "mat_r2"]
    output:
        pat_hapmer=config["output"]["base"] + "/{sample}/assembly/verkko_trio/hapmers/paternal_compress.k30.hapmer.only.meryl",
        mat_hapmer=config["output"]["base"] + "/{sample}/assembly/verkko_trio/hapmers/maternal_compress.k30.hapmer.only.meryl"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/assembly/verkko_trio/hapmers"
    threads:
        get_threads("verkko_trio_prep", 32)
    resources:
        mem_mb=get_mem_mb("verkko_trio_prep", 256000)
    log:
        "logs/assembly/verkko_trio_prep/{sample}.log"
    singularity:
        config.get("images", {}).get("merqury", "")
    shell:
        """
        /bin/bash workflow/scripts/assembly/verkko_trio_prep.sh \
            {params.output_dir} \
            {input.pat_r1} \
            {input.pat_r2} \
            {input.mat_r1} \
            {input.mat_r2} \
            {threads} &> {log}
        """


# ====================================================================
# Verkko with trio-binning
# ====================================================================
rule verkko_trio:
    input:
        ont_fastq=lambda wc: samples.loc[wc.sample, "ont_fastq"],
        hifi_fastq=lambda wc: samples.loc[wc.sample, "hifi_fastq"],
        pat_r1=lambda wc: samples.loc[wc.sample, "pat_r1"],
        pat_r2=lambda wc: samples.loc[wc.sample, "pat_r2"],
        mat_r1=lambda wc: samples.loc[wc.sample, "mat_r1"],
        mat_r2=lambda wc: samples.loc[wc.sample, "mat_r2"],
        pat_hapmer=config["output"]["base"] + "/{sample}/assembly/verkko_trio/hapmers/paternal_compress.k30.hapmer.only.meryl",
        mat_hapmer=config["output"]["base"] + "/{sample}/assembly/verkko_trio/hapmers/maternal_compress.k30.hapmer.only.meryl"
    output:
        hap1=config["output"]["base"] + "/{sample}/assembly/verkko_trio/assembly/assembly.haplotype1.fasta",
        hap2=config["output"]["base"] + "/{sample}/assembly/verkko_trio/assembly/assembly.haplotype2.fasta",
        primary=config["output"]["base"] + "/{sample}/assembly/verkko_trio/assembly/assembly.fasta"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/assembly/verkko_trio"
    threads:
        get_threads("verkko_trio", 16)
    resources:
        mem_mb=get_mem_mb("verkko_trio", 480000)
    log:
        "logs/assembly/verkko_trio/{sample}.log"
    singularity:
        config.get("images", {}).get("verkko", "")
    shell:
        """
        /bin/bash workflow/scripts/assembly/verkko_trio.sh \
            {params.output_dir} \
            {params.sample} \
            {input.ont_fastq} \
            {input.hifi_fastq} \
            {input.pat_r1} \
            {input.pat_r2} \
            {input.mat_r1} \
            {input.mat_r2} \
            {params.output_dir} &> {log}
        """
