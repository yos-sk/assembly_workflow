#!/usr/bin/env python3
"""Add one validated row to the workflow sample sheet.

Build up config/samples.tsv one sample at a time from the command line. The
script infers sensible defaults (assembly_mode from the reads/phasing you pass,
assembler from the mode, run_modules), validates read file extensions, and
checks the resulting sheet against workflow/schemas/samples.schema.yaml.

Examples
--------
# HiFi + Hi-C, hifiasm (mode + assembler inferred)
python3 set_sample_sheet.py --sample S1 --sex male \
    --hifi /data/S1.hifi.bam --hic-r1 /data/S1_R1.fq.gz --hic-r2 /data/S1_R2.fq.gz

# Verkko + Pore-C (assembler inferred as verkko)
python3 set_sample_sheet.py --sample S2 --sex male --assembly-mode verkko_porec \
    --hifi /data/S2.hifi.fq.gz --ont /data/S2.ont.fq.gz --porec /data/S2.porec.fq.gz

# Evaluate/annotate existing assemblies (no assembly_mode -> run_modules defaults
# to annotation,evaluation)
python3 set_sample_sheet.py --sample S3 --sex female \
    --hap1-assembly /data/S3.hap1.fa --hap2-assembly /data/S3.hap2.fa --hifi /data/S3.hifi.bam
"""

import argparse
import csv
import os
import sys

import yaml

# Column order written to the TSV.
COLUMNS = [
    "sample", "assembler", "sex", "run_modules", "assembly_mode",
    "hap1_assembly", "hap2_assembly",
    "hifi", "ont", "ont_ul", "hic_r1", "hic_r2", "porec",
    "pat_r1", "pat_r2", "mat_r1", "mat_r2",
    "illumina_r1", "illumina_r2", "ont_platform",
]

ASSEMBLY_MODES = [
    "hifiasm", "hifiasm_hic", "hifiasm_trio",
    "verkko_hic", "verkko_porec", "verkko_trio",
]

# hifi/ont accept BAM or FASTQ; everything else is FASTQ only.
READ_EXTS = (".bam", ".fastq", ".fq", ".fastq.gz", ".fq.gz")
FASTQ_EXTS = (".fastq", ".fq", ".fastq.gz", ".fq.gz")

SCHEMA_PATH = "workflow/schemas/samples.schema.yaml"


def die(msg):
    sys.exit(f"error: {msg}")


def split_paths(value):
    """Comma-separated paths -> stripped list."""
    return [p.strip() for p in value.split(",") if p.strip()]


def check_exts(value, label, allowed):
    """Validate that each comma-separated path ends with an allowed extension."""
    if not value:
        return
    for p in split_paths(value):
        low = p.lower()
        if not low.endswith(allowed):
            die(f"{label}: '{p}' must be one of {allowed}")


def infer_assembly_mode(args):
    """Pick an assembly_mode from the provided inputs (hifiasm family by default)."""
    if args.assembly_mode:
        return args.assembly_mode
    # Existing assemblies supplied -> don't generate; reads (if any) are for
    # annotation/evaluation.
    if args.hap1_assembly or args.hap2_assembly:
        return ""
    if args.porec:
        return "verkko_porec"          # Pore-C phasing is Verkko-only
    if args.pat_r1 or args.mat_r1:
        return "hifiasm_trio"
    if args.hic_r1 or args.hic_r2:
        return "hifiasm_hic"
    if args.hifi or args.ont:
        return "hifiasm"
    return ""


def infer_assembler(mode, explicit):
    """assembler label: explicit > Verkko for verkko_* modes > hifiasm default."""
    if explicit:
        return explicit
    if mode.startswith("verkko"):
        return "verkko"
    return "hifiasm"


def infer_run_modules(args, mode):
    if args.run_modules:
        return args.run_modules
    # Pre-existing assemblies with no generation step -> downstream only.
    if not mode and (args.hap1_assembly or args.hap2_assembly):
        return "annotation,evaluation"
    return "all"


def validate_inputs(args, mode):
    """Cross-field checks beyond the JSON schema (paired/required-by-mode inputs)."""
    check_exts(args.hifi, "--hifi", READ_EXTS)
    check_exts(args.ont, "--ont", READ_EXTS)
    check_exts(args.ont_ul, "--ont-ul", READ_EXTS)
    for val, label in [
        (args.hic_r1, "--hic-r1"), (args.hic_r2, "--hic-r2"), (args.porec, "--porec"),
        (args.pat_r1, "--pat-r1"), (args.pat_r2, "--pat-r2"),
        (args.mat_r1, "--mat-r1"), (args.mat_r2, "--mat-r2"),
        (args.illumina_r1, "--illumina-r1"), (args.illumina_r2, "--illumina-r2"),
    ]:
        check_exts(val, label, FASTQ_EXTS)

    # Paired reads must come together.
    if bool(args.hic_r1) != bool(args.hic_r2):
        die("Hi-C needs both --hic-r1 and --hic-r2")
    if bool(args.illumina_r1) != bool(args.illumina_r2):
        die("Illumina needs both --illumina-r1 and --illumina-r2")

    # Mode-specific requirements.
    if mode in ("hifiasm_hic", "verkko_hic") and not (args.hic_r1 and args.hic_r2):
        die(f"{mode} requires --hic-r1 and --hic-r2")
    if mode == "verkko_porec" and not args.porec:
        die("verkko_porec requires --porec")
    if mode in ("hifiasm_trio", "verkko_trio") and not all(
        [args.pat_r1, args.pat_r2, args.mat_r1, args.mat_r2]
    ):
        die(f"{mode} requires --pat-r1/--pat-r2/--mat-r1/--mat-r2")
    if mode.startswith("verkko") and not args.hifi:
        die(f"{mode} requires --hifi (HiFi / ONT-Duplex / HERRO-corrected)")
    if mode.startswith("hifiasm") and not (args.hifi or args.ont):
        die(f"{mode} requires --hifi and/or --ont (ultra-long ONT alone cannot assemble)")
    if not mode and not (args.hap1_assembly and args.hap2_assembly):
        die("no assembly_mode: provide --hap1-assembly and --hap2-assembly")


def build_row(args):
    mode = infer_assembly_mode(args)
    validate_inputs(args, mode)
    assembler = infer_assembler(mode, args.assembler)
    run_modules = infer_run_modules(args, mode)
    ont_platform = args.ont_platform or ("ONT-R10" if (args.ont or args.ont_ul) else "")

    row = {c: "" for c in COLUMNS}
    row.update({
        "sample": args.sample,
        "assembler": assembler,
        "sex": args.sex,
        "run_modules": run_modules,
        "assembly_mode": mode,
        "hap1_assembly": args.hap1_assembly or "",
        "hap2_assembly": args.hap2_assembly or "",
        "hifi": args.hifi or "",
        "ont": args.ont or "",
        "ont_ul": args.ont_ul or "",
        "hic_r1": args.hic_r1 or "",
        "hic_r2": args.hic_r2 or "",
        "porec": args.porec or "",
        "pat_r1": args.pat_r1 or "",
        "pat_r2": args.pat_r2 or "",
        "mat_r1": args.mat_r1 or "",
        "mat_r2": args.mat_r2 or "",
        "illumina_r1": args.illumina_r1 or "",
        "illumina_r2": args.illumina_r2 or "",
        "ont_platform": ont_platform,
    })
    return row


def load_rows(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def write_rows(path, rows):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, delimiter="\t", restval="",
                           extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def schema_validate(rows):
    try:
        import jsonschema
    except ImportError:
        print("warning: jsonschema not installed; skipping schema validation",
              file=sys.stderr)
        return
    with open(SCHEMA_PATH) as f:
        schema = yaml.safe_load(f)
    for row in rows:
        # Drop empty cells so enum/typed optional fields are not validated as "".
        instance = {k: v for k, v in row.items() if v not in ("", None)}
        try:
            jsonschema.validate(instance=instance, schema=schema)
        except jsonschema.ValidationError as e:
            die(f"schema validation failed for sample '{row.get('sample')}': {e.message}")


def create_parser():
    p = argparse.ArgumentParser(
        description="Add one validated row to the workflow sample sheet.",
        formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    p.add_argument("--samplesheet", default="config/samples.tsv",
                   help="sample sheet to create/append to (default: config/samples.tsv)")
    p.add_argument("--sample", required=True, help="sample identifier")
    p.add_argument("--sex", required=True, choices=["male", "female"])
    p.add_argument("--assembler", default="",
                   help="output label (default: inferred from assembly_mode, else hifiasm)")
    p.add_argument("--assembly-mode", dest="assembly_mode", default="",
                   choices=[""] + ASSEMBLY_MODES,
                   help="assembly mode (default: inferred from inputs)")
    p.add_argument("--run-modules", dest="run_modules", default="",
                   help="comma-separated assembly/annotation/evaluation or 'all' "
                        "(default: inferred)")
    # Reads / inputs
    p.add_argument("--hifi", default="", help="HiFi reads (BAM or FASTQ, comma-separated)")
    p.add_argument("--ont", default="",
                   help="standard/simplex ONT reads (hifiasm --ont base; BAM or FASTQ)")
    p.add_argument("--ont-ul", dest="ont_ul", default="",
                   help="ultra-long ONT reads (hifiasm --ul / verkko --nano; BAM or FASTQ)")
    p.add_argument("--hic-r1", dest="hic_r1", default="")
    p.add_argument("--hic-r2", dest="hic_r2", default="")
    p.add_argument("--porec", default="")
    p.add_argument("--pat-r1", dest="pat_r1", default="")
    p.add_argument("--pat-r2", dest="pat_r2", default="")
    p.add_argument("--mat-r1", dest="mat_r1", default="")
    p.add_argument("--mat-r2", dest="mat_r2", default="")
    p.add_argument("--illumina-r1", dest="illumina_r1", default="")
    p.add_argument("--illumina-r2", dest="illumina_r2", default="")
    p.add_argument("--ont-platform", dest="ont_platform", default="",
                   choices=["", "ONT-R9", "ONT-R10"],
                   help="ONT platform (default: ONT-R10 when --ont is given)")
    p.add_argument("--hap1-assembly", dest="hap1_assembly", default="")
    p.add_argument("--hap2-assembly", dest="hap2_assembly", default="")
    p.add_argument("--force", action="store_true",
                   help="replace an existing row with the same sample name")
    return p


def main():
    args = create_parser().parse_args()
    row = build_row(args)

    rows = load_rows(args.samplesheet)
    names = [r["sample"] for r in rows]
    if args.sample in names:
        if not args.force:
            die(f"sample '{args.sample}' already in {args.samplesheet} (use --force to replace)")
        rows[names.index(args.sample)] = row
        action = "updated"
    else:
        rows.append(row)
        action = "added"

    schema_validate(rows)
    write_rows(args.samplesheet, rows)
    print(f"{action} '{args.sample}' (assembler={row['assembler']}, "
          f"assembly_mode={row['assembly_mode'] or '-'}, run_modules={row['run_modules']}) "
          f"-> {args.samplesheet}")


if __name__ == "__main__":
    main()
