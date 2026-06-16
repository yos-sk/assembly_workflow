#!/usr/bin/env python3
"""
Setup script for the assembly workflow.
Generates config.yaml and a runner shell script from command-line arguments.

Modeled after PRCGAP/setup_workflow.py: a single CLI invocation produces
both the snakemake config file and the runner script that drives it.
"""

import argparse
import os
import stat
import sys
import yaml
from pathlib import Path


# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

# (config-key, default) for host paths exposed to the workflow via
# config["tools"][...]. Every other tool path used to live here, but the
# corresponding binaries are now baked into the singularity images (or
# hardcoded inside the rule scripts, e.g. /opt/dna-nn-0.1/models/attcc-alpha.knm).
# Only compleasm_library remains because the BUSCO DB is too large to
# bundle into the compleasm image.
_TOOL_DEFAULTS = [
    ("compleasm_library", ""),
]

# Singularity image keys consumed via config["images"][<key>] in the rules.
# When the user does not supply --<key>-image explicitly we fall back to
# <images-dir>/<key>.sif.
_IMAGE_KEYS = [
    "alignment",
    "censat_alphasat",
    "censat_asat_summarize",
    "censat_hmmer",
    "censat_hsat",
    "censat_rm2bed",
    "censat_tools",
    "chain_files",
    "compleasm",
    "dna_nn",
    "flagger",
    "hifiasm",
    "inspector",
    "liftoff",
    "mashmap",
    "merqury",
    "nucflag",
    "pstools",
    "repeatmasker",
    "sedef",
    "trf_mod",
    "verkko",
    "yak",
]

# Reference files referenced by the workflow (config["references"][<key>]).
_REFERENCE_KEYS = [
    "chm13",
    "grch38",
    "chm13_satellite",
    "grch38_centromeres",
    "grch38_exclusions",
    "grch38_gtf",
]

# (rule-name, default-cpus, default-mem-per-cpu) per resource override.
_RESOURCE_DEFAULTS = [
    # Assembly
    ("hifiasm", 56, "8G"),
    ("hifiasm_hic", 56, "8G"),
    ("hifiasm_trio", 56, "8G"),
    ("verkko_hic", 16, "30G"),
    ("verkko_porec", 16, "30G"),
    ("verkko_trio_prep", 32, "8G"),
    ("verkko_trio", 16, "30G"),
    # Annotation
    ("assembly_filter", 16, "8G"),
    ("chain_files", 16, "8G"),
    ("liftoff", 50, "8G"),
    ("trf_mod", 1, "100G"),
    ("dna_nn", 16, "5G"),
    ("repeatmasker", 24, "12G"),
    ("sedef", 14, "8G"),
    ("filter_sedef", 1, "10G"),
    ("censat_split", 1, "30G"),
    ("censat_alphasat", 56, "8G"),
    ("censat_rdna", 24, "8G"),
    ("censat_gaps", 1, "30G"),
    ("censat_hsat", 1, "30G"),
    ("censat_repeatmasker", 1, "30G"),
    ("censat_create", 1, "30G"),
    ("censat_create_asat_bed", 1, "30G"),
    # Evaluation
    ("alignment_hifi", 16, "8G"),
    ("alignment_ont", 16, "8G"),
    ("flagger", 16, "8G"),
    ("inspector", 16, "16G"),
    ("nucflag", 16, "8G"),
    ("merqury", 16, "8G"),
    ("yak", 16, "8G"),
    ("yak_trioeval", 32, "8G"),
    ("pstools", 56, "8G"),
    ("compleasm", 16, "8G"),
]


# Profile config.yaml keys whose values are paths to scripts living inside
# the profile dir; snakemake resolves them relative to cwd (not the profile
# dir), so we rewrite them to absolute paths.
_PROFILE_PATH_KEYS = (
    "jobscript",
    "cluster",
    "cluster-status",
    "cluster-cancel",
    "cluster-generic-submit-cmd",
    "cluster-generic-status-cmd",
    "cluster-generic-cancel-cmd",
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _abs(path):
    """Absolutise a path WITHOUT following symlinks. Empty/None passes through.

    Snakemake runs with cwd=--directory (output base), so any relative path
    in config.yaml would resolve under the output dir and miss the user's
    input files. We absolutise at config-generation time.

    We use os.path.abspath rather than Path.resolve() so symlinks like
    /home/<user> -> /hshare1/.../home/<user> stay as the user-facing path.
    Following symlinks would yield paths that aren't bind-mounted into the
    singularity/apptainer container.
    """
    if not path:
        return path
    return os.path.abspath(os.path.expanduser(path))


def _image_path(explicit, images_dir, key):
    """Return user-supplied image path or fall back to <images_dir>/<key>.sif."""
    if explicit:
        return explicit
    if not images_dir:
        return ""
    return os.path.join(images_dir, f"{key}.sif")


def _absolutise_profile_paths(profile_dir: Path):
    """Rewrite path-valued keys in <profile_dir>/config.yaml to absolute.

    Only rewrites values that resolve to an existing file inside the profile
    dir, so already-absolute or already-resolved paths are left alone.
    """
    cfg = profile_dir / "config.yaml"
    if not cfg.exists():
        return
    with open(cfg) as f:
        data = yaml.safe_load(f) or {}

    changed = False
    for key in _PROFILE_PATH_KEYS:
        val = data.get(key)
        if not isinstance(val, str) or not val:
            continue
        if Path(val).is_absolute():
            continue
        candidate = Path(os.path.abspath(profile_dir / val))
        if candidate.exists():
            data[key] = str(candidate)
            changed = True

    if changed:
        with open(cfg, "w") as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)


# ---------------------------------------------------------------------------
# Config / runner generation
# ---------------------------------------------------------------------------

def create_config(args):
    """Build the config dict from parsed CLI arguments."""
    config = {
        "samples": _abs(args.samplesheet),
        "output": {
            "base": _abs(args.output_dir),
        },
        "references": {
            key: _abs(getattr(args, key)) or ""
            for key in _REFERENCE_KEYS
        },
        "tools": {
            key: _abs(getattr(args, key)) or ""
            for key, _ in _TOOL_DEFAULTS
        },
        "images": {
            "base": _abs(args.images_dir) or "",
            **{
                key: _abs(_image_path(getattr(args, f"{key}_image"), args.images_dir, key))
                for key in _IMAGE_KEYS
            },
        },
        "resources": {
            name: {
                "cpus": getattr(args, f"{name}_cpus"),
                "mem_per_cpu": getattr(args, f"{name}_mem_per_cpu"),
            }
            for name, _, _ in _RESOURCE_DEFAULTS
        },
        # Per-rule singularity controls. `bind` mirrors --singularity-bind so
        # rules that invoke singularity themselves (e.g. repeatmasker) can
        # apply the same mounts the global --singularity-args would.
        "singularity": {
            "bind": args.singularity_bind or "",
            "repeatmasker_args": args.repeatmasker_singularity_args,
        },
        "params": {
            "assembly_filter": {
                "min_length": args.filter_min_length,
            },
            "trf_mod": {
                "match": args.trf_match,
                "mismatch": args.trf_mismatch,
                "delta": args.trf_delta,
                "pm": args.trf_pm,
                "pi": args.trf_pi,
                "minscore": args.trf_minscore,
                "maxperiod": args.trf_maxperiod,
                "minlength": args.trf_minlength,
            },
        },
    }
    # The assembly_filter rule has no dedicated SIF; it reuses the dna_nn image.
    config["images"]["assembly_filter"] = config["images"]["dna_nn"]
    return config


def write_runner(args, config_path: Path, runner_path: Path):
    """Emit a runner shell script invoking snakemake.

    Pattern (after PRCGAP/setup_workflow.py):
      - With --profile  -> snakemake --profile <profile> ...
      - Without         -> snakemake -j <jobs> ...
      - Always uses --use-singularity (conda is not supported).
    """
    workflow_dir = _abs(args.workflow_dir)
    snakefile = os.path.join(workflow_dir, "Snakefile")
    output_dir = _abs(args.output_dir)
    config_abs = _abs(str(config_path))

    cmd_lines = ["#!/bin/bash", "set -euo pipefail", ""]

    cmd_parts = [
        "snakemake",
        f"--snakefile {snakefile}",
        f"--configfile {config_abs}",
        f"--directory {output_dir}",
    ]

    if args.profile:
        profile_path = Path(_abs(args.profile))
        # Snakemake interprets path-valued keys inside profile/config.yaml
        # (jobscript, cluster, cluster-status, cluster-cancel, and the v8
        # cluster-generic-* equivalents) relative to cwd, not to the profile
        # dir, so they break under --directory. Rewrite bare-name values to
        # absolute paths.
        _absolutise_profile_paths(profile_path)
        cmd_parts.append(f"--profile {profile_path}")

    cmd_parts.append(f"-j {args.jobs}")

    # Effective target: explicit --target wins, otherwise default to "all".
    # The Snakefile's `all` rule expands each module's targets over only the
    # samples whose run_modules request that module, so "all" runs exactly what
    # each sample's run_modules column asks for (assembly-only, annotation-only,
    # evaluation-only, or every module). --with-assembly is accepted but ignored
    # (kept for backwards compatibility).
    target = args.target or "all"
    if target:
        cmd_parts.append(target)

    cmd_parts.append("--use-singularity")
    if args.singularity_bind:
        cmd_parts.append(f'--singularity-args "-B {args.singularity_bind} -e"')

    cmd_parts.extend([
        "--rerun-triggers mtime",
        "--rerun-incomplete",
        "--keep-going",
        '"$@"',
    ])

    cmd_lines.append(" \\\n    ".join(cmd_parts))
    cmd_lines.append("")

    runner_path.parent.mkdir(parents=True, exist_ok=True)
    runner_path.write_text("\n".join(cmd_lines))
    runner_path.chmod(runner_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser():
    parser = argparse.ArgumentParser(
        description="Setup assembly workflow (config + runner script)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # 1. Local run, images staged under ./images/
  python setup_workflow.py \\
    --samplesheet config/samples.tsv \\
    --chm13 /path/to/chm13.fa \\
    --grch38 /path/to/GRCh38.fa \\
    --images-dir /path/to/images \\
    --jobs 8

  # 2. Cluster run via profile
  python setup_workflow.py \\
    --samplesheet config/samples.tsv \\
    --chm13 /path/to/chm13.fa \\
    --grch38 /path/to/GRCh38.fa \\
    --images-dir /path/to/images \\
    --profile profile/slurm

  # Override a single image
  python setup_workflow.py ... --hifiasm-image /path/to/custom.sif

  # Target only annotation
  python setup_workflow.py ... --target annotation
        """,
    )

    # ---------- Required I/O ----------
    parser.add_argument("--samplesheet", required=True,
                        help="sample sheet TSV (becomes config['samples'])")

    # ---------- References ----------
    ref_group = parser.add_argument_group(
        "References",
        "Reference files. --chm13 and --grch38 are typically required by the "
        "workflow; the rest are optional and may be left empty.",
    )
    ref_group.add_argument("--chm13", default="",
                           help="CHM13 reference FASTA")
    ref_group.add_argument("--grch38", default="",
                           help="GRCh38 reference FASTA")
    ref_group.add_argument("--chm13-satellite", dest="chm13_satellite", default="",
                           help="CHM13 CenSat annotation BED")
    ref_group.add_argument("--grch38-centromeres", dest="grch38_centromeres", default="",
                           help="GRCh38 centromeres file")
    ref_group.add_argument("--grch38-exclusions", dest="grch38_exclusions", default="",
                           help="GRCh38 exclusion regions BED")
    ref_group.add_argument("--grch38-gtf", dest="grch38_gtf", default="",
                           help="GRCh38 GTF annotation file")

    # ---------- Host tools ----------
    tool_group = parser.add_argument_group(
        "Host tools",
        "Paths to host binaries / data consumed by the workflow scripts. "
        "Leave blank to populate the key as an empty string in config.yaml.",
    )
    for name, default in _TOOL_DEFAULTS:
        flag = "--" + name.replace("_", "-")
        tool_group.add_argument(flag, dest=name, default=default,
                                help=f"path for tools.{name}")

    # ---------- Singularity images ----------
    img_group = parser.add_argument_group(
        "Singularity images",
        "Pass --images-dir to use <dir>/<key>.sif for every image. Override "
        "individual images with --<key>-image. Empty --images-dir + no "
        "explicit override leaves the entry as an empty string.",
    )
    img_group.add_argument("--images-dir", default="",
                           help="directory containing prepared singularity images "
                                "(default: empty; image entries become empty strings "
                                "unless overridden)")
    for key in _IMAGE_KEYS:
        flag = f"--{key.replace('_', '-')}-image"
        img_group.add_argument(flag, dest=f"{key}_image", default=None,
                               help=f"override images.{key} "
                                    f"(default: <images-dir>/{key}.sif)")

    # ---------- Resources (per-module overrides) ----------
    res_group = parser.add_argument_group(
        "Per-rule resources",
        "Override cpus / mem_per_cpu for individual rules. All optional; "
        "omitted values fall back to the defaults shown below.",
    )
    for name, default_cpus, default_mem in _RESOURCE_DEFAULTS:
        flag_base = name.replace("_", "-")
        res_group.add_argument(
            f"--{flag_base}-cpus",
            type=int, default=default_cpus,
            help=f"cpus for {name} (default: {default_cpus})",
        )
        res_group.add_argument(
            f"--{flag_base}-mem-per-cpu",
            default=default_mem,
            help=f"mem_per_cpu for {name} (default: {default_mem})",
        )

    # ---------- Params ----------
    p_group = parser.add_argument_group("Filter / TRF-mod parameters")
    p_group.add_argument("--filter-min-length", type=int, default=100000,
                         help="min contig length for filter step (default: 100000)")
    p_group.add_argument("--trf-match", type=int, default=2,
                         help="TRF-mod match score (default: 2)")
    p_group.add_argument("--trf-mismatch", type=int, default=7,
                         help="TRF-mod mismatch penalty (default: 7)")
    p_group.add_argument("--trf-delta", type=int, default=7,
                         help="TRF-mod indel penalty (default: 7)")
    p_group.add_argument("--trf-pm", type=int, default=80,
                         help="TRF-mod match probability (default: 80)")
    p_group.add_argument("--trf-pi", type=int, default=10,
                         help="TRF-mod indel probability (default: 10)")
    p_group.add_argument("--trf-minscore", type=int, default=50,
                         help="TRF-mod min score (default: 50)")
    p_group.add_argument("--trf-maxperiod", type=int, default=2000,
                         help="TRF-mod max period (default: 2000)")
    p_group.add_argument("--trf-minlength", type=int, default=30,
                         help="TRF-mod min length (default: 30)")

    # ---------- Output / runner ----------
    out_group = parser.add_argument_group("Output / runner")
    out_group.add_argument("--output-dir", default="../output",
                           help="snakemake working directory for results "
                                "(default: ../output)")
    out_group.add_argument("--output", "-o", default="config/config.yaml",
                           help="path for generated config.yaml "
                                "(default: config/config.yaml)")
    out_group.add_argument("--runner", default="run_workflow.sh",
                           help="path for generated runner shell script "
                                "(default: run_workflow.sh)")
    out_group.add_argument("--workflow-dir", default="workflow",
                           help="snakemake workflow directory containing Snakefile "
                                "(default: workflow)")
    out_group.add_argument("--target", default="",
                           help="snakemake target rule(s) to bake into the runner "
                                "(e.g. 'assembly', 'annotation', 'evaluation', or a "
                                "space-separated list). Empty (default) = 'all', "
                                "which runs each sample's run_modules.")
    out_group.add_argument("--with-assembly", action="store_true", default=False,
                           help="deprecated / no-op: the runner now defaults to the "
                                "'all' target, which already honours the run_modules "
                                "column per sample (assembly included when listed). "
                                "Kept only so existing commands don't break.")
    out_group.add_argument("--force", "-f", action="store_true", default=False,
                           help="overwrite existing config / runner files")

    # ---------- Executor / container backend ----------
    exec_group = parser.add_argument_group("Executor / container backend")
    exec_group.add_argument("--profile", default=None,
                            help="snakemake profile path (e.g. profile/slurm). "
                                 "When set, jobs run via the profile instead of "
                                 "locally.")
    exec_group.add_argument("--jobs", "-j", type=int, default=8,
                            help="max concurrent jobs (locally: parallel rules; "
                                 "with --profile: jobs queued). default: 8")
    exec_group.add_argument("--singularity-bind", default="",
                            help='extra bind paths for singularity, e.g. '
                                 '"/data,/scratch"')
    exec_group.add_argument("--repeatmasker-singularity-args",
                            default="--net --network=none",
                            help="extra singularity exec args applied only to "
                                 "the repeatmasker rule (which invokes "
                                 "singularity manually, since snakemake has no "
                                 "per-rule --singularity-args). "
                                 'default: "--net --network=none". '
                                 "Pass an empty string to disable.")

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    config_path = Path(args.output)
    runner_path = Path(args.runner)

    for p in (config_path, runner_path):
        if p.exists() and not args.force:
            print(f"Error: {p} already exists. Use --force to overwrite.",
                  file=sys.stderr)
            sys.exit(1)

    config_path.parent.mkdir(parents=True, exist_ok=True)
    config = create_config(args)

    with open(config_path, "w") as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    print(f"✓ Configuration written to {config_path}")

    write_runner(args, config_path, runner_path)
    print(f"✓ Runner script written to {runner_path}")

    if args.profile:
        print(f"\nExecutor: snakemake profile {args.profile}")
    else:
        print(f"\nExecutor: local (-j {args.jobs})")
    print("Container backend: singularity")


if __name__ == "__main__":
    main()
