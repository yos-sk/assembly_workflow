"""
Common functions and sample loading for assembly workflow
"""

import pandas as pd
from snakemake.utils import validate


# Load and validate configuration
configfile: "config/config.yaml"
validate(config, schema="../schemas/config.schema.yaml")


# Load sample sheet
samples = pd.read_csv(config["samples"], sep="\t", dtype=str)
samples.set_index("sample", drop=False, inplace=True)


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
    return f"singularity exec {extra_args} -e {bind_arg} {image}"


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


def get_raw_assembly_outputs(wildcards):
    """Get raw assembly outputs based on assembly mode
    Returns paths to haplotype assemblies, either from:
    - Assembly rules output (if assembly_mode is specified)
    - Existing assembly files (from samples.tsv)
    """
    sample = wildcards.sample
    mode = get_assembly_mode(sample)

    base = config['output']['base']

    if mode == "hifiasm_hic":
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
