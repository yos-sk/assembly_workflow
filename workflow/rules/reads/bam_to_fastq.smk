"""
Read preparation.

Reads come from a single column per category: `hifi` and `ont`. Each holds one
or more comma-separated paths whose type is decided by file extension:
  - *.bam                  -> converted to FASTQ with `samtools fastq`
  - *.fastq[.gz] / *.fq[.gz] -> used as FASTQ

A single FASTQ file is passed straight through. Anything that needs work (a
BAM, or several files to concatenate) is normalized into one gzipped FASTQ at
{base}/{sample}/reads/{hifi,ont}/{sample}_{hifi,ont}.fastq.gz.
"""


def reads_list(sample, category):
    """Comma-separated paths from the `hifi`/`ont` column ([] when absent)."""
    val = col_value(sample, category)
    if not val:
        return []
    return [p.strip() for p in val.split(",") if p.strip()]


def is_bam(path):
    return path.lower().endswith(".bam")


def needs_prepare(files):
    """True if reads must be normalized: any BAM, or more than one file."""
    return len(files) > 1 or any(is_bam(f) for f in files)


def _resolved_fastq(sample, category):
    files = reads_list(sample, category)
    if not files:
        return []
    if needs_prepare(files):
        return config["output"]["base"] + "/" + sample + "/reads/" + category + "/" + sample + "_" + category + ".fastq.gz"
    # Single FASTQ: use it directly, no preparation step.
    return files[0]


def get_hifi_fastq(wildcards):
    """HiFi FASTQ path: direct FASTQ, normalized output, or [] when absent.

    Returning [] (rather than NaN) lets a rule treat HiFi as optional - the
    named input expands to an empty string in the shell, so quote it.
    """
    return _resolved_fastq(wildcards.sample, "hifi")


def get_ont_fastq(wildcards):
    """Standard/simplex ONT FASTQ path (the `ont` column); [] when absent."""
    return _resolved_fastq(wildcards.sample, "ont")


def get_ont_ul_fastq(wildcards):
    """Ultra-long ONT FASTQ path (the `ont_ul` column); [] when absent."""
    return _resolved_fastq(wildcards.sample, "ont_ul")


def get_ont_eval_fastq(wildcards):
    """ONT reads to use for evaluation (alignment / Flagger-ONT).

    Ultra-long ONT is preferred; fall back to standard ONT; [] if neither.
    """
    if reads_list(wildcards.sample, "ont_ul"):
        return _resolved_fastq(wildcards.sample, "ont_ul")
    return _resolved_fastq(wildcards.sample, "ont")


# ====================================================================
# Normalize reads to a single gzipped FASTQ.
# Handles BAM (samtools fastq) and FASTQ (cat/zcat) inputs, and concatenates
# multiple files. Only runs when a sample needs it (see needs_prepare).
# ====================================================================
rule prepare_hifi_reads:
    input:
        reads=lambda wc: reads_list(wc.sample, "hifi")
    output:
        fastq=config["output"]["base"] + "/{sample}/reads/hifi/{sample}_hifi.fastq.gz"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/reads/hifi",
        reads=lambda wc: " ".join(reads_list(wc.sample, "hifi"))
    threads:
        get_threads("prepare_hifi", 8)
    resources:
        mem_mb=get_mem_mb("prepare_hifi", 32768)
    log:
        "logs/reads/{sample}/prepare_hifi_reads.log"
    singularity:
        config.get("images", {}).get("alignment", "")
    shell:
        """
        mkdir -p {params.output_dir}
        for f in {params.reads}; do
            case "$f" in
                *.bam)        samtools fastq -@ {threads} "$f" ;;
                *.gz)         zcat "$f" ;;
                *.fastq|*.fq) cat "$f" ;;
                *)            echo "ERROR: unrecognized read file: $f" >&2; exit 1 ;;
            esac
        done 2>> {log} | gzip -c > {output.fastq}
        echo "Prepared HiFi reads for {params.sample}" >> {log}
        """


rule prepare_ont_reads:
    input:
        reads=lambda wc: reads_list(wc.sample, "ont")
    output:
        fastq=config["output"]["base"] + "/{sample}/reads/ont/{sample}_ont.fastq.gz"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/reads/ont",
        reads=lambda wc: " ".join(reads_list(wc.sample, "ont"))
    threads:
        get_threads("prepare_ont", 8)
    resources:
        mem_mb=get_mem_mb("prepare_ont", 32768)
    log:
        "logs/reads/{sample}/prepare_ont_reads.log"
    singularity:
        config.get("images", {}).get("alignment", "")
    shell:
        """
        mkdir -p {params.output_dir}
        for f in {params.reads}; do
            case "$f" in
                *.bam)        samtools fastq -@ {threads} "$f" ;;
                *.gz)         zcat "$f" ;;
                *.fastq|*.fq) cat "$f" ;;
                *)            echo "ERROR: unrecognized read file: $f" >&2; exit 1 ;;
            esac
        done 2>> {log} | gzip -c > {output.fastq}
        echo "Prepared ONT reads for {params.sample}" >> {log}
        """


rule prepare_ont_ul_reads:
    input:
        reads=lambda wc: reads_list(wc.sample, "ont_ul")
    output:
        fastq=config["output"]["base"] + "/{sample}/reads/ont_ul/{sample}_ont_ul.fastq.gz"
    params:
        sample="{sample}",
        output_dir=config["output"]["base"] + "/{sample}/reads/ont_ul",
        reads=lambda wc: " ".join(reads_list(wc.sample, "ont_ul"))
    threads:
        get_threads("prepare_ont_ul", 8)
    resources:
        mem_mb=get_mem_mb("prepare_ont_ul", 32768)
    log:
        "logs/reads/{sample}/prepare_ont_ul_reads.log"
    singularity:
        config.get("images", {}).get("alignment", "")
    shell:
        """
        mkdir -p {params.output_dir}
        for f in {params.reads}; do
            case "$f" in
                *.bam)        samtools fastq -@ {threads} "$f" ;;
                *.gz)         zcat "$f" ;;
                *.fastq|*.fq) cat "$f" ;;
                *)            echo "ERROR: unrecognized read file: $f" >&2; exit 1 ;;
            esac
        done 2>> {log} | gzip -c > {output.fastq}
        echo "Prepared ultra-long ONT reads for {params.sample}" >> {log}
        """
