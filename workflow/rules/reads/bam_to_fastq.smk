"""
BAM to FASTQ conversion
Converts input BAM files to FASTQ format for alignment and evaluation
Supports multiple BAM files per sample (comma-separated in samples.tsv)
"""


def get_hifi_bam_list(wildcards):
    """Get list of HiFi BAM files for a sample (comma-separated in samples.tsv)"""
    bam_str = samples.loc[wildcards.sample, "hifi_bam"]
    return [b.strip() for b in bam_str.split(",")]


def get_ont_bam(wildcards):
    """Get ONT BAM file for a sample"""
    return samples.loc[wildcards.sample, "ont_bam"]


def get_hifi_fastq(wildcards):
    """Get HiFi FASTQ path - either from BAM conversion or direct from samples.tsv"""
    if "hifi_bam" in samples.columns and pd.notna(samples.loc[wildcards.sample, "hifi_bam"]) and samples.loc[wildcards.sample, "hifi_bam"] != "":
        return config["output"]["base"] + f"/{wildcards.sample}/reads/hifi/{wildcards.sample}_hifi.fastq.gz"
    return samples.loc[wildcards.sample, "hifi_fastq"]


def get_ont_fastq(wildcards):
    """Get ONT FASTQ path - either from BAM conversion or direct from samples.tsv"""
    if "ont_bam" in samples.columns and pd.notna(samples.loc[wildcards.sample, "ont_bam"]) and samples.loc[wildcards.sample, "ont_bam"] != "":
        return config["output"]["base"] + f"/{wildcards.sample}/reads/ont/{wildcards.sample}_ont.fastq.gz"
    return samples.loc[wildcards.sample, "ont_fastq"]


# ====================================================================
# HiFi BAM to FASTQ conversion
# Supports multiple BAM files - converts and concatenates
# ====================================================================
rule hifi_bam_to_fastq:
    input:
        bams=get_hifi_bam_list
    output:
        fastq=config["output"]["base"] + "/{sample}/reads/hifi/{sample}_hifi.fastq.gz"
    params:
        sample="{sample}",
        samtools=config["tools"]["samtools"],
        output_dir=config["output"]["base"] + "/{sample}/reads/hifi",
        bam_list=lambda wc: " ".join(get_hifi_bam_list(wc))
    threads:
        8
    resources:
        mem_mb=32768
    log:
        "logs/reads/{sample}/hifi_bam_to_fastq.log"
    shell:
        """
        mkdir -p {params.output_dir}

        # Convert each BAM to FASTQ and concatenate
        BAM_FILES=({params.bam_list})
        if [ ${{#BAM_FILES[@]}} -eq 1 ]; then
            # Single BAM file
            {params.samtools} fastq -@ {threads} "${{BAM_FILES[0]}}" 2>> {log} | gzip -c > {output.fastq}
        else
            # Multiple BAM files - convert and concatenate
            for bam in "${{BAM_FILES[@]}}"; do
                {params.samtools} fastq -@ {threads} "$bam" 2>> {log}
            done | gzip -c > {output.fastq}
        fi

        echo "HiFi BAM to FASTQ conversion complete for {params.sample}" >> {log}
        """


# ====================================================================
# ONT BAM to FASTQ conversion
# ====================================================================
rule ont_bam_to_fastq:
    input:
        bam=get_ont_bam
    output:
        fastq=config["output"]["base"] + "/{sample}/reads/ont/{sample}_ont.fastq.gz"
    params:
        sample="{sample}",
        samtools=config["tools"]["samtools"],
        output_dir=config["output"]["base"] + "/{sample}/reads/ont"
    threads:
        8
    resources:
        mem_mb=32768
    log:
        "logs/reads/{sample}/ont_bam_to_fastq.log"
    shell:
        """
        mkdir -p {params.output_dir}
        {params.samtools} fastq -@ {threads} {input.bam} 2> {log} | gzip -c > {output.fastq}
        echo "ONT BAM to FASTQ conversion complete for {params.sample}" >> {log}
        """
