"""
Common functions and sample loading for assembly workflow
"""

import pandas as pd
from snakemake.utils import validate


# Load and validate configuration
configfile: "config/config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# Defensive: strip stray whitespace from the output base so it does not leak into
# every generated path (Snakemake warns about, and may mis-match, such paths).
config["output"]["base"] = str(config["output"]["base"]).strip()


# Load and validate sample sheet. Validation enforces the assembly_mode enum,
# so unsupported modes (e.g. no-phasing verkko, which cannot produce hap1/hap2)
# fail loudly at startup instead of silently falling through to existing-assembly
# mode. Empty optional cells (NaN) are skipped by snakemake's validate.
samples = pd.read_csv(config["samples"], sep="\t", dtype=str)
# Strip surrounding whitespace from headers and every cell, so a space-padded
# sheet doesn't inject spaces into sample names / paths (which then show up in
# output paths and break Snakemake's file matching).
samples.columns = samples.columns.str.strip()
samples = samples.apply(lambda c: c.str.strip() if c.dtype == "object" else c)
samples.set_index("sample", drop=False, inplace=True)
validate(samples, schema="../schemas/samples.schema.yaml")


def col_value(sample, column):
    """Return a stripped sample-sheet value, or None if the column is
    missing / empty / NaN. Use this to treat optional read types uniformly."""
    if column in samples.columns:
        val = samples.loc[sample, column]
        if pd.notna(val) and str(val).strip() != "":
            return str(val).strip()
    return None


def get_sample_assembler(wildcards):
    """Get assembler for a sample"""
    return samples.loc[wildcards.sample, "assembler"]


def get_hap1_assembly(wildcards):
    """Get haplotype 1 assembly path for a sample"""
    return samples.loc[wildcards.sample, "hap1_assembly"]


def get_hap2_assembly(wildcards):
    """Get haplotype 2 assembly path for a sample"""
    return samples.loc[wildcards.sample, "hap2_assembly"]


def get_sample_sex(wildcards):
    """Get sex for a sample"""
    return samples.loc[wildcards.sample, "sex"]


def get_threads(rule_name, default=8):
    """Get number of threads for a rule from config

    Args:
        rule_name: Name of the rule in config['resources']
        default: Default number of threads if not specified in config

    Returns:
        Number of threads (int)
    """
    return config.get("resources", {}).get(rule_name, {}).get("cpus", default)


def get_mem_mb(rule_name, default=64000):
    """Get memory in MB for a rule from config

    Args:
        rule_name: Name of the rule in config['resources']
        default: Default memory in MB if not specified in config

    Returns:
        Memory in MB (int)

    Note:
        This function calculates: threads * mem_per_cpu
        mem_per_cpu is expected to be in format like "8G" or "8000"
    """
    resources = config.get("resources", {}).get(rule_name, {})
    cpus = resources.get("cpus", 8)
    mem_per_cpu = resources.get("mem_per_cpu", "8G")

    # Parse mem_per_cpu (handle formats like "8G" or "8000")
    if isinstance(mem_per_cpu, str):
        if mem_per_cpu.endswith("G"):
            mem_per_cpu_mb = int(mem_per_cpu.rstrip("G")) * 1024
        elif mem_per_cpu.endswith("M"):
            mem_per_cpu_mb = int(mem_per_cpu.rstrip("M"))
        else:
            mem_per_cpu_mb = int(mem_per_cpu)
    else:
        mem_per_cpu_mb = int(mem_per_cpu)

    return cpus * mem_per_cpu_mb


def get_mem_per_cpu_gb(rule_name, default="8G"):
    """Get per-CPU memory in GB for a rule from config (for UGE s_vmem)

    Args:
        rule_name: Name of the rule in config['resources']
        default: Default mem_per_cpu string

    Returns:
        Memory per CPU in GB (int)
    """
    resources = config.get("resources", {}).get(rule_name, {})
    mem_per_cpu = resources.get("mem_per_cpu", default)

    if isinstance(mem_per_cpu, str):
        if mem_per_cpu.endswith("G"):
            return int(mem_per_cpu.rstrip("G"))
        elif mem_per_cpu.endswith("M"):
            return max(1, int(mem_per_cpu.rstrip("M")) // 1024)
        else:
            return max(1, int(mem_per_cpu) // 1024)
    else:
        return max(1, int(mem_per_cpu) // 1024)


def get_repeatmasker_singularity_cmd():
    """Build the `singularity exec ...` prefix used by the repeatmasker_hap rule.

    Snakemake has no per-rule equivalent of --singularity-args, so we drop
    the `singularity:` directive on this one rule and invoke singularity
    manually. The `--net --network=none` flag isolates RepeatMasker from
    the network; it's specific to this rule and must not leak to others.

    Binds: the workflow basedir and the output base are always mounted
    (mirroring what `--use-singularity` would do automatically). Any extra
    paths set via `singularity.bind` in config are appended.
    """
    image = config.get("images", {}).get("repeatmasker", "")
    extra_args = config.get("singularity", {}).get(
        "repeatmasker_args", "--net --network=none"
    )
    binds = [workflow.basedir, config["output"]["base"]]
    user_bind = config.get("singularity", {}).get("bind", "")
    if user_bind:
        binds.extend(p for p in user_bind.split(",") if p)
    bind_arg = "-B " + ",".join(binds)
    # Optional host-env prefix exported only for this rule's singularity call,
    # e.g. "SINGULARITYENV_GLIBC_TUNABLES=glibc.pthread.rseq=0". Set via
    # singularity.repeatmasker_env in config (setup_workflow.py
    # --repeatmasker-singularity-env). Empty by default.
    env_prefix = str(config.get("singularity", {}).get("repeatmasker_env", "")).strip()
    env_prefix = f"{env_prefix} " if env_prefix else ""
    return f"{env_prefix}singularity exec {extra_args} -e {bind_arg} {image}"


def get_reference_fasta(wildcards, reference):
    """Get reference FASTA file, removing Y chromosome for female samples
    Note: Reference files are stored in a shared location, not per-sample
    """
    sex = samples.loc[wildcards.sample, "sex"]
    if sex == "female":
        return f"db/references/{reference}.masked_noY.fa"
    else:
        return f"db/references/{reference}.masked.fa"


def get_filtered_assembly(wildcards):
    """Get filtered assembly FASTA files
    Returns paths to filtered assembly files in the new directory structure:
    {base}/{sample}/assembly/filter/{assembler}/
    """
    sample = wildcards.sample
    assembler = samples.loc[sample, "assembler"]
    base = config['output']['base']
    return {
        "hap1": f"{base}/{sample}/assembly/filter/{assembler}/{sample}.hap1.filt.fa",
        "hap2": f"{base}/{sample}/assembly/filter/{assembler}/{sample}.hap2.filt.fa",
        "combined": f"{base}/{sample}/assembly/filter/{assembler}/{sample}.filt.fa"
    }


def get_assembly_mode(sample):
    """Get assembly mode for a sample"""
    if "assembly_mode" in samples.columns:
        mode = samples.loc[sample, "assembly_mode"]
        # Check if mode is not NaN/None/empty
        if pd.notna(mode) and mode != "":
            return mode
    # If no assembly_mode specified, return None (use existing assemblies)
    return None


def get_run_modules(sample):
    """Get modules to run for a sample

    Returns:
        set: Set of modules to run ('assembly', 'annotation', 'evaluation')
    """
    if "run_modules" in samples.columns:
        run_modules_str = samples.loc[sample, "run_modules"]
        if pd.notna(run_modules_str) and run_modules_str != "":
            if run_modules_str.lower() == "all":
                return {"assembly", "annotation", "evaluation"}
            # Parse comma-separated list
            modules = {m.strip().lower() for m in run_modules_str.split(",")}
            # Validate module names
            valid_modules = {"assembly", "annotation", "evaluation"}
            return modules & valid_modules
    # Default: run all modules
    return {"assembly", "annotation", "evaluation"}


def should_run_assembly(sample):
    """Check if assembly should be run for this sample"""
    modules = get_run_modules(sample)
    return "assembly" in modules


def should_run_annotation(sample):
    """Check if annotation should be run for this sample"""
    modules = get_run_modules(sample)
    return "annotation" in modules


def should_run_evaluation(sample):
    """Check if evaluation should be run for this sample"""
    modules = get_run_modules(sample)
    return "evaluation" in modules


def has_hifi(sample):
    """True if the sample provides HiFi reads (BAM or FASTQ in the `hifi` column)."""
    return bool(col_value(sample, "hifi"))


def has_ont(sample):
    """True if the sample provides standard ONT reads (the `ont` column)."""
    return bool(col_value(sample, "ont"))


def has_ont_ul(sample):
    """True if the sample provides ultra-long ONT reads (the `ont_ul` column)."""
    return bool(col_value(sample, "ont_ul"))


def get_raw_assembly_outputs(wildcards):
    """Get raw assembly outputs based on assembly mode
    Returns paths to haplotype assemblies, either from:
    - Assembly rules output (if assembly_mode is specified)
    - Existing assembly files (from samples.tsv)
    """
    sample = wildcards.sample
    mode = get_assembly_mode(sample)

    base = config['output']['base']

    if mode == "hifiasm":
        return {
            "hap1": f"{base}/{sample}/assembly/hifiasm/{sample}.hap1.fa",
            "hap2": f"{base}/{sample}/assembly/hifiasm/{sample}.hap2.fa"
        }
    elif mode == "hifiasm_hic":
        return {
            "hap1": f"{base}/{sample}/assembly/hifiasm_hic/{sample}.hap1.fa",
            "hap2": f"{base}/{sample}/assembly/hifiasm_hic/{sample}.hap2.fa"
        }
    elif mode == "hifiasm_trio":
        return {
            "hap1": f"{base}/{sample}/assembly/hifiasm_trio/{sample}.hap1.fa",
            "hap2": f"{base}/{sample}/assembly/hifiasm_trio/{sample}.hap2.fa"
        }
    elif mode == "verkko_hic":
        return {
            "hap1": f"{base}/{sample}/assembly/verkko_hic/assembly/assembly.haplotype1.fasta",
            "hap2": f"{base}/{sample}/assembly/verkko_hic/assembly/assembly.haplotype2.fasta"
        }
    elif mode == "verkko_porec":
        return {
            "hap1": f"{base}/{sample}/assembly/verkko_porec/assembly/assembly.haplotype1.fasta",
            "hap2": f"{base}/{sample}/assembly/verkko_porec/assembly/assembly.haplotype2.fasta"
        }
    elif mode == "verkko_trio":
        return {
            "hap1": f"{base}/{sample}/assembly/verkko_trio/assembly/assembly.haplotype1.fasta",
            "hap2": f"{base}/{sample}/assembly/verkko_trio/assembly/assembly.haplotype2.fasta"
        }
    else:
        # If no assembly mode specified, use existing assembly paths from samples.tsv
        return {
            "hap1": samples.loc[sample, "hap1_assembly"],
            "hap2": samples.loc[sample, "hap2_assembly"]
        }
