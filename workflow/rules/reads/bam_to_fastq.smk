"""
BAM to FASTQ conversion
Converts input BAM files to FASTQ format for alignment and evaluation
Supports multiple BAM files per sample (comma-separated in samples.tsv)
"""


def get_hifi_bam_list(wildcards):
    """Get list of HiFi BAM files for a sample (comma-separated in samples.tsv)"""
    bam_str = samples.loc[wildcards.sample, "hifi_bam"]
    return [b.strip() for b in bam_str.split(",")]


def get_ont_bam_list(wildcards):
    """Get list of ONT BAM files for a sample (comma-separated in samples.tsv)"""
    bam_str = samples.loc[wildcards.sample, "ont_bam"]
    return [b.strip() for b in bam_str.split(",")]


def get_hifi_fastq(wildcards):
    """HiFi FASTQ path: from BAM conversion, direct FASTQ, or [] when absent.

    Returning [] (rather than NaN) lets a rule treat HiFi as optional - the
    named input expands to an empty string in the shell, so quote it.
    """
    sample = wildcards.sample
    if col_value(sample, "hifi_bam"):
        return config["output"]["base"] + f"/{sample}/reads/hifi/{sample}_hifi.fastq.gz"
    return col_value(sample, "hifi_fastq") or []


def get_ont_fastq(wildcards):
    """ONT FASTQ path: from BAM conversion, direct FASTQ, or [] when absent.

    Returning [] (rather than NaN) lets a rule treat ONT as optional - the
    named input expands to an empty string in the shell, so quote it.
    """
    sample = wildcards.sample
    if col_value(sample, "ont_bam"):
        return config["output"]["base"] + f"/{sample}/reads/ont/{sample}_ont.fastq.gz"
    return col_value(sample, "ont_fastq") or []


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
        output_dir=config["output"]["base"] + "/{sample}/reads/hifi",
        bam_list=lambda wc: " ".join(get_hifi_bam_list(wc))
    threads:
        8
    resources:
        mem_mb=32768
    log:
        "logs/reads/{sample}/hifi_bam_to_fastq.log"
    singularity:
        config.get("images", {}).get("alignment", "")
    shell:
        """
        mkdir -p {params.output_dir}

        # Convert each BAM to FASTQ and concatenate
        BAM_FILES=({params.bam_list})
        if [ ${{#BAM_FILES[@]}} -eq 1 ]; then
            # Single BAM file
            samtools fastq -@ {threads} "${{BAM_FILES[0]}}" 2>> {log} | gzip -c > {output.fastq}
        else
            # Multiple BAM files - convert and concatenate
            for bam in "${{BAM_FILES[@]}}"; do
                samtools fastq -@ {threads} "$bam" 2>> {log}
            done | gzip -c > {output.fastq}
        fi

        echo "HiFi BAM to FASTQ conversion complete for {params.sample}" >> {log}
        """


# ====================================================================
# ONT BAM to FASTQ conversion
# Supports multiple BAM files - converts and concatenates
# ====================================================================
rule ont_bam_to_fastq:
    input:
        bams=get_ont_bam_list
    output:
        fastq=config["output"]["base"] + "/{sample}/reads/ont/{sample}_ont.fastq.gz"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/reads/ont",
        bam_list=lambda wc: " ".join(get_ont_bam_list(wc))
    threads:
        8
    resources:
        mem_mb=32768
    log:
        "logs/reads/{sample}/ont_bam_to_fastq.log"
    singularity:
        config.get("images", {}).get("alignment", "")
    shell:
        """
        mkdir -p {params.output_dir}

        # Convert each BAM to FASTQ and concatenate
        BAM_FILES=({params.bam_list})
        if [ ${{#BAM_FILES[@]}} -eq 1 ]; then
            # Single BAM file
            samtools fastq -@ {threads} "${{BAM_FILES[0]}}" 2>> {log} | gzip -c > {output.fastq}
        else
            # Multiple BAM files - convert and concatenate
            for bam in "${{BAM_FILES[@]}}"; do
                samtools fastq -@ {threads} "$bam" 2>> {log}
            done | gzip -c > {output.fastq}
        fi

        echo "ONT BAM to FASTQ conversion complete for {params.sample}" >> {log}
        """
