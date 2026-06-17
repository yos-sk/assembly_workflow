# Assembly Workflow

> ## 📖 New here? → Start with the **[Tutorial](docs/TUTORIAL.md)**
>
> A hands-on, end-to-end walkthrough on real GIAB **HG008** data: pull images →
> build a sample sheet → dry run → run → read the outputs. Begin with the chr20
> quick run to exercise the whole pipeline in minutes. **The rest of this README
> is the option reference behind it.**

A Snakemake workflow for genome **assembly generation**, **annotation**, and **quality evaluation**, packaged with Singularity/Apptainer images so the only host requirements are Snakemake and a container runtime.

It adapts to the data you have: provide HiFi only, ONT only, or both — with or without phasing data (Hi-C / Pore-C / trio) — and the workflow runs the steps your inputs can support and skips the rest.

---

## What it does

Three modules, selected per sample via the `run_modules` column (`assembly`, `annotation`, `evaluation`, or `all`):

- **Assembly** — generate a phased assembly with hifiasm or Verkko, then filter and rename contigs.
- **Annotation** — annotate genes, repeats, satellites, segmental duplications, and centromeres.
- **Evaluation** — assess assembly quality and detect misassemblies.

### When each step runs

A step runs only if its module is enabled **and** its required inputs are present. "Always" means it runs whenever the module is enabled.

| Module | Step | Runs when |
|--------|------|-----------|
| **Assembly** | hifiasm / Verkko (per `assembly_mode`) | `assembly` enabled **and** `assembly_mode` set |
| | Filter + contig rename | **always** — also runs as a prerequisite of annotation/evaluation |
| **Annotation** | chain files, Liftoff, TRF-mod, dna-nn, RepeatMasker, SEDEF, CenSat | **always** (read-independent; needs CHM13/GRCh38 references) |
| **Evaluation** | Flagger (HiFi) · Inspector · NucFlag · yak QV | requires **HiFi** reads |
| | Flagger (ONT) | requires **ONT** reads |
| | T2T · compleasm | **always** (assembly only) |
| | Merqury | requires **Illumina** reads |
| | pstools (phasing QC) | requires **Hi-C** reads |
| | yak trioeval | requires **parental (trio)** reads |

> Filter is the shared prerequisite for annotation and evaluation, so it runs whenever either module runs — even if `assembly` is not in `run_modules` (in that case it filters the assemblies you supply via `hap1_assembly`/`hap2_assembly`).

---

## What you can run with your data

The workflow picks the right invocation from the reads you provide. Use this to see which assembly modes and evaluations your data unlocks.

### Assembly modes by available data

| You have | `assembly_mode` options |
|----------|-------------------------|
| HiFi only | `hifiasm` |
| ONT only (`ont`) | `hifiasm` (uses hifiasm `--ont`) |
| HiFi + ultra-long ONT (`ont_ul`) | `hifiasm` (ONT added via `--ul`) |
| … + Hi-C | `hifiasm_hic`, `verkko_hic` |
| … + Pore-C | `verkko_porec` |
| … + parental (trio) | `hifiasm_trio`, `verkko_trio` |

> **Verkko requires accurate long reads in the `hifi` column** (PacBio HiFi, ONT Duplex, or HERRO-corrected simplex); ultra-long ONT in the `ont_ul` column is optional `--nano` support (the simplex `ont` column is not used by Verkko). Verkko cannot assemble from raw ONT simplex alone, and it is only offered with phasing (it does not emit haplotype1/2 without it). For a no-phasing assembly, use `hifiasm`.

### Evaluations by available data

Each input *adds* evaluations on top of the read-independent baseline:

| You have | Evaluations it adds |
|----------|---------------------|
| any assembly (baseline) | T2T, compleasm |
| + HiFi | Flagger (HiFi), Inspector, NucFlag, yak QV |
| + ONT (`ont_ul` preferred, else `ont`) | Flagger (ONT) |
| + Hi-C | pstools (phasing/switch QC) |
| + parental (trio) | yak trioeval |
| + Illumina | Merqury |

---

## Prerequisites

- **Snakemake** (>= 7.0, < 8.0)
- **Singularity / Apptainer** — every per-tool dependency runs inside a container
- **Python 3** with `pyyaml` (for `setup_workflow.py`; included with Snakemake)
- **cookiecutter** *(optional — only to generate a cluster profile from a template; see Setup step 2)*

All tool dependencies (hifiasm, Verkko, RepeatMasker, Flagger, …) ship as Singularity images pulled by `images/pull_image.sh`. Nothing else needs to be installed on the host.

A quick install with [mamba](https://github.com/mamba-org/mamba):

```bash
# Snakemake (+ pyyaml for setup_workflow.py) in a dedicated environment
mamba create -n assembly_workflow -c conda-forge -c bioconda "snakemake>=7,<8" pyyaml

# Singularity/Apptainer — Linux only (not available on macOS).
# On an HPC it is often provided instead via: module load apptainer
mamba install -n assembly_workflow -c conda-forge apptainer

# cookiecutter (optional, only for generating a cluster profile)
mamba install -n assembly_workflow -c conda-forge cookiecutter

# Activate the environment.
mamba activate assembly_workflow # or just put the env on PATH: export PATH=PATH_to_assembly_workflow_env:$PATH"
```

---

## Quick start

The condensed command sequence is below. For a guided, step-by-step version with
a worked example, a dry run, and how to read the results, follow the
**[Tutorial](docs/TUTORIAL.md)**.

```bash
# 0. Clone the repository and enter it (run all later commands from here).
git clone https://github.com/yos-sk/assembly_workflow.git
cd assembly_workflow

# 1. Pull the Singularity images (run from inside images/)
cd images && bash pull_image.sh
cd ..

# 2. (Cluster only) generate a Snakemake profile. If you run locally, please skip this step.
template="gh:Snakemake-Profiles/slurm"     # or gh:Snakemake-Profiles/sge
cookiecutter --output-dir profile $template # Please set the environment

# 3. Download references (first time), build the sample sheet, then generate config + runner.
bash download_reference.sh reference
bash download_compleasm_db.sh reference/mb_downloads
( cd workflow/scripts/annotation/censat/db && bash download.sh )   # CenSat HMM/k-mer DB (annotation)
SHEET=config/samples.tsv

# (a) --run-modules all: generate the assembly from reads, then annotate and evaluate it.
python3 set_sample_sheet.py --samplesheet $SHEET --sample S1 --sex male --run-modules all \
    --assembler hifiasm \
    --hifi /data/S1.hifi.bam --ont-ul /data/S1.ont_ul.bam \
    --hic-r1 /data/S1_R1.fq.gz --hic-r2 /data/S1_R2.fq.gz

# (b) --run-modules evaluation,annotation: skip assembly generation and run only
#     evaluation + annotation on existing assemblies (pass them via --hap1/2-assembly).
python3 set_sample_sheet.py --samplesheet $SHEET --sample S2 --sex female \
    --run-modules evaluation,annotation --assembler verkko \
    --hap1-assembly /data/S2.hap1.fa --hap2-assembly /data/S2.hap2.fa \
    --hifi /data/S2.hifi.bam        # second sample appended to the same sheet (optional)
#    (or copy config/samples.tsv.template and edit by hand; see "Sample sheet" below)

python3 setup_workflow.py \
    --samplesheet $SHEET \
    --output config/config.yaml \      # generated config (default: config/config.yaml)
    --runner run_workflow.sh \         # generated runner script (default: run_workflow.sh)
    --chm13 reference/chm13v2.0_maskedY_rCRS.fa \
    --grch38 reference/GRCh38.d1.vd1.fa \
    --chm13-satellite reference/chm13v2.0_censat_v2.1.bed \
    --grch38-centromeres reference/centromeres.txt.gz \
    --grch38-exclusions reference/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed \
    --grch38-gtf reference/Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf \
    --compleasm-library reference/mb_downloads \
    --images-dir images \
    --singularity-bind "$HOME" \   # bind input/output tree into the containers; see "Setup" for the HPC symlink caveat
    --profile profile/slurm        # omit for local execution
#   add --force (-f) when re-generating over an existing config / runner

# 4. Run (default target = all enabled modules per sample)
./run_workflow.sh
```

`./run_workflow.sh` runs the default `all` target, which builds each sample's enabled modules — so a sample with `--run-modules all` gets assembly, annotation, and evaluation, while one set to e.g. `evaluation` gets only that.

---

## Setup

### 0. Clone the repository

```bash
git clone https://github.com/yos-sk/assembly_workflow.git
cd assembly_workflow
```

Run all the commands below from this repository root.

### 1. Pull Singularity images

All containers are listed in `images/pull_image.sh` and stored as `images/<image-key>.sif`. The image keys match the keys consumed by `config["images"][...]` in the workflow rules, so once they sit in one directory with these names, `setup_workflow.py --images-dir images` (step 3) wires everything automatically.

Run it from inside `images/` so the `.sif` files land there. **For a normal setup this single command is all you need** — it pulls every image that is not already present:

```bash
cd images
bash pull_image.sh
cd ..
```

The forms below are optional variants — use one *instead of* the plain command only when needed, not in addition:

```bash
bash pull_image.sh --force          # re-pull everything, overwriting existing .sif
bash pull_image.sh hifiasm yak      # pull only the listed image keys
```

### 2. (Cluster only) Snakemake profile

Skip this for local runs. On a cluster, generate a profile with cookiecutter (installed in the Prerequisites step).

```bash
template="gh:Snakemake-Profiles/slurm"   # or gh:Snakemake-Profiles/sge, .../lsf, .../pbs-torque
cookiecutter --output-dir profile $template
```

Cookiecutter then asks 17 questions. A typical SLURM walkthrough (the profile name becomes the directory under `profile/`):

```text
[1/17]  profile_name (slurm):                        # accept default or e.g. assembly-slurm
[2/17]  Select use_singularity                       # ► 2 (True)  — every rule runs in a container
        1 - False
        2 - True
[3/17]  Select use_conda                             # ► 1 (False) — the workflow does not use conda envs
        1 - False
        2 - True
[4/17]  jobs (500):                                  # max concurrent SLURM jobs; 64–500 is typical
[5/17]  restart_times (0):                           # 1 is reasonable; retries transient SLURM failures once
[6/17]  max_status_checks_per_second (10):           # keep default unless your scheduler is rate-limited
[7/17]  max_jobs_per_second (10):                    # keep default
[8/17]  latency_wait (5):                            # bump to 60–120 on Lustre / NFS (see note below)
[9/17]  Select print_shell_commands                  # ► 1 (False) — keep snakemake's log compact
        1 - False
        2 - True
[10/17] sbatch_defaults:                             # site-specific, e.g. "partition=cpuq account=myacct"
        # other options (qos, time, mail-user, …) can also be appended here as space-separated key=value
[11/17] cluster_sidecar_help:                        # informational; press Enter
[12/17] Select cluster_sidecar                       # ► 1 (yes) on Snakemake 7.x — one sidecar process
        1 - yes                                      #     batches squeue/sacct calls
        2 - no
[13/17] cluster_name:                                # optional free-form label; leave empty unless you
                                                     #   run multiple clusters from the same login node
[14/17] cluster_jobname ({rule}.{jobid}):            # accept default; expands per job
[15/17] cluster_logpath (logs/slurm/{rule}/%j):      # accept default; paths are created automatically
[16/17] cluster_config_help:                         # informational; press Enter
[17/17] cluster_config:                              # leave empty — deprecated in favor of resources
```

> On shared (Lustre/NFS) filesystems, raise `latency_wait` to 60–120 s so Snakemake waits for output files to appear before declaring a job failed.

This produces `profile/<name>/` with `config.yaml` plus the `*-submit.py` / `*-status.py` / `*-jobscript.sh` (and `*-sidecar.py`) scripts.

Pass the resulting directory to `setup_workflow.py --profile profile/<name>` in step 3.

### 3. Sample sheet → config + runner script

First build the sample sheet, then run `setup_workflow.py` to turn it into `config/config.yaml` and a runner script `run_workflow.sh`.

**Build the sample sheet with `set_sample_sheet.py` (recommended).** It appends one validated row per call, so run it once per sample. For each sample it:

- infers `assembly_mode` from the inputs you pass (Hi-C → `*_hic`, Pore-C → `verkko_porec`, trio reads → `*_trio`, otherwise plain `hifiasm`), defaulting to the hifiasm family;
- takes `assembler` from `--assembler` (specify `hifiasm` or `verkko` explicitly; it names the `{assembler}` output subdirectory) and derives `run_modules` (`all`, or `annotation,evaluation` when you give existing assemblies);
- detects each read file's type by extension (`.bam` vs `.fastq`/`.fq`[`.gz`]) and checks paired/mode-required inputs;
- validates the whole sheet against `workflow/schemas/samples.schema.yaml`.

```bash
# one call per sample (--force replaces a row with the same --sample);
# --samplesheet defaults to config/samples.tsv. `python3 set_sample_sheet.py --help` lists all flags.
python3 set_sample_sheet.py --sample S1 --sex male --run-modules all \
    --assembler hifiasm \
    --hifi /data/S1.hifi.bam --ont-ul /data/S1.ont_ul.bam \
    --hic-r1 /data/S1_R1.fq.gz --hic-r2 /data/S1_R2.fq.gz
```

Or copy `config/samples.tsv.template` and edit it by hand (column reference under "Sample sheet" below).

**Download references (first time).** Annotation and the compleasm/T2T evaluations need a set of reference and annotation files. Two helper scripts fetch and format them:

```bash
bash download_reference.sh reference          # genome FASTAs + CenSat/centromeres/exclusions/GTF
bash download_compleasm_db.sh reference/mb_downloads   # compleasm BUSCO lineage (primates_odb10)
```

The **CenSat** annotation step also needs HMM profiles and HSat k-mer tables.
They are large, so they are not committed — fetch them once into the script's
`db/` directory (the scripts expect them there):

```bash
( cd workflow/scripts/annotation/censat/db && bash download.sh )
```

`download_reference.sh` writes into the directory you pass (default `reference/`): `chm13v2.0_maskedY_rCRS.fa`, `GRCh38.d1.vd1.fa`, `chm13v2.0_censat_v2.1.bed`, `centromeres.txt.gz`, `GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed`, and the reformatted `Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf`.

**Generate config + runner:**

```bash
python3 setup_workflow.py \
    --samplesheet config/samples.tsv \
    --output config/config.yaml \      # generated config (default: config/config.yaml)
    --runner run_workflow.sh \         # generated runner script (default: run_workflow.sh)
    --chm13 reference/chm13v2.0_maskedY_rCRS.fa \
    --grch38 reference/GRCh38.d1.vd1.fa \
    --chm13-satellite reference/chm13v2.0_censat_v2.1.bed \
    --grch38-centromeres reference/centromeres.txt.gz \
    --grch38-exclusions reference/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed \
    --grch38-gtf reference/Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf \
    --compleasm-library reference/mb_downloads \
    --images-dir images \
    --singularity-bind "$HOME" \   # bind your home dir into the containers
    --profile profile/slurm        # omit for local execution
```

This writes `config/config.yaml` (use `--output` to change the path) and `run_workflow.sh` (use `--runner`). `python3 setup_workflow.py --help` lists every flag (per-rule resources, per-image overrides, TRF/filter parameters, …).

> **Re-generating?** `setup_workflow.py` refuses to overwrite an existing `config/config.yaml` or `run_workflow.sh`. On the **second and later runs** add `--force` (`-f`) to replace them.

> **`--singularity-bind`.** Singularity/Apptainer only mounts a default set of paths into the container; files outside them are invisible, so rules fail to find inputs. Pass the directories holding your reads, references, and outputs as a comma-separated list (e.g. `--singularity-bind "$HOME"`, or `"/data,/scratch"`). The value becomes `--singularity-args "-B <paths> -e"` in the runner and the per-rule `bind`. Because `setup_workflow.py`/`set_sample_sheet.py` absolutise every path under your home directory, binding `$HOME` is usually enough.
>
> **HPC caveat — check the actual path prefix.** `set_sample_sheet.py` keeps paths as written (it does **not** resolve symlinks), but on many clusters `$HOME` (e.g. `/home/<user>`) is a symlink to physical storage like `/lustre/home/<user>`, and that real prefix is what must be bind-mounted. **Inspect the absolute paths `set_sample_sheet.py` wrote into `config/samples.tsv`** (`column -t -s$'\t' config/samples.tsv`) and bind whatever prefix they actually use — e.g. `--singularity-bind "/lustre"` rather than `"$HOME"` if the rows show `/lustre/home/...`.

---

## Sample sheet

Tab-separated. Only `sample`, `assembler`, and `sex` are required; everything else depends on which modules and inputs you use.

### Build it with `set_sample_sheet.py` (recommended)

Instead of editing the TSV by hand, add one validated row at a time. Specify the `assembler` (`hifiasm` or `verkko`) with `--assembler`; the script infers `assembly_mode` from the inputs (defaulting to the `hifiasm` family), derives `run_modules`, checks read file extensions, and validates the sheet against the schema.

```bash
# HiFi + Hi-C  ->  assembly_mode=hifiasm_hic, run_modules=all
python3 set_sample_sheet.py --sample S1 --sex male --assembler hifiasm \
    --hifi /data/S1.hifi.bam --hic-r1 /data/S1_R1.fq.gz --hic-r2 /data/S1_R2.fq.gz

# Existing assemblies  ->  no assembly_mode, run_modules=annotation,evaluation
python3 set_sample_sheet.py --sample S3 --sex female --assembler verkko \
    --hap1-assembly /data/S3.hap1.fa --hap2-assembly /data/S3.hap2.fa --hifi /data/S3.hifi.bam
```

Writes to `config/samples.tsv` by default (`--samplesheet` to change, `--force` to replace a row). `python3 set_sample_sheet.py --help` lists all options. The columns it fills are described below.

### Columns

**Identity (required)**
- `sample` — sample identifier (used in output paths).
- `assembler` — free-form label for organizing outputs (e.g. `hifiasm_0.25.0`, `verkko_2.2.1`); it names the `{assembler}` output subdirectory. The actual generator is chosen by `assembly_mode`.
- `sex` — `male` or `female`. Controls chrY handling: female drops chrY from the reference during filtering; male consolidates chrX/chrY onto single haplotypes.

**Module control**
- `run_modules` — comma-separated list of `assembly`, `annotation`, `evaluation`, or `all` (default when empty: all). Each sample runs only its listed modules.

**Assembly generation**
- `assembly_mode` — one of `hifiasm`, `hifiasm_hic`, `hifiasm_trio`, `verkko_hic`, `verkko_porec`, `verkko_trio`. Omit it to skip generation and use existing assemblies.

**Reads** (file type is detected by extension: `*.bam` is converted to FASTQ, `*.fastq`/`*.fq`[`.gz`] is used directly; multiple comma-separated paths are concatenated)
- `hifi` — HiFi reads.
- `ont` — standard/simplex ONT reads. Used as the hifiasm ONT-only assembly base (`--ont`), and as the evaluation fallback when `ont_ul` is absent.
- `ont_ul` — ultra-long ONT reads. Added to any assembly via hifiasm `--ul` / verkko `--nano`, and preferred for evaluation (Flagger-ONT). With HiFi present, only `ont_ul` is used for assembly (the `ont` column is not).
- `hic_r1`, `hic_r2` — Hi-C reads (required for `*_hic`; enables pstools).
- `porec` — Pore-C reads (required for `verkko_porec`).
- `pat_r1`, `pat_r2`, `mat_r1`, `mat_r2` — parental reads (required for `*_trio`; enables yak trioeval).
- `illumina_r1`, `illumina_r2` — Illumina reads (enables Merqury).
- `ont_platform` — `ONT-R9` or `ONT-R10` (default `ONT-R10`; used by Flagger).

**Existing assemblies** (when `assembly_mode` is omitted)
- `hap1_assembly`, `hap2_assembly` — paths to haplotype FASTAs to annotate/evaluate.

### Example

```tsv
sample  assembler       sex     run_modules            assembly_mode  hifi              ont_ul             hic_r1             hic_r2             hap1_assembly      hap2_assembly
S1      hifiasm_0.25.0  male    all                    hifiasm_hic    /data/hifi.bam    /data/ont_ul.bam   /data/hic_R1.fq.gz /data/hic_R2.fq.gz
S2      verkko_2.2.1    female  annotation,evaluation                 /data/hifi.fq.gz  /data/ont_ul.fq.gz                                       /data/S2.hap1.fa   /data/S2.hap2.fa
```

### Common scenarios

```tsv
# Full run, HiFi + Hi-C, hifiasm
sample  assembler  sex   run_modules  assembly_mode  hifi            hic_r1            hic_r2
S1      hifiasm    male  all          hifiasm_hic    /data/hifi.bam  /data/hic1.fq.gz  /data/hic2.fq.gz
```
```tsv
# Annotate existing assemblies only
sample  assembler  sex   run_modules  hap1_assembly       hap2_assembly
S1      hifiasm    male  annotation   /data/S1.hap1.fa    /data/S1.hap2.fa
```
```tsv
# Evaluate existing assemblies (HiFi present -> HiFi evaluations; add ont for Flagger-ONT)
sample  assembler  sex   run_modules  hap1_assembly      hap2_assembly      hifi
S1      verkko     male  evaluation   /data/S1.hap1.fa   /data/S1.hap2.fa   /data/hifi.fq.gz
```
```tsv
# Assembly + evaluation, Verkko + Pore-C (skip annotation)
sample  assembler  sex   run_modules          assembly_mode  hifi             ont_ul             porec
S2      verkko     male  assembly,evaluation  verkko_porec   /data/hifi.fq.gz /data/ont_ul.fq.gz /data/porec.fq.gz
```

---

## Outputs

Everything is written under `{output.base}/{sample}/`. Within a module, paths are grouped by the `{assembler}` label.

```
{output.base}/{sample}/
├── assembly/
│   ├── {assembler}/                 # raw assembly (when generated)
│   └── filter/{assembler}/          # length-filtered, reference-oriented,
│                                    #   PanSN-renamed contigs ({sample}#{hap}#{chrom})
├── annotation/{chain_files,liftoff,trf_mod,dna_nn,repeatmasker,segdup,censat}/{assembler}/
└── evaluation/
    ├── alignment/{assembler}/{hifi,ont}/    # read alignments (BAM)
    ├── flagger/{assembler}/{hifi,ont}/      # misassembly predictions + summary
    ├── inspector/{assembler}/               # structural/small-scale errors (HiFi)
    ├── nucflag/{assembler}/                 # nucleotide-level misassemblies (HiFi)
    ├── yak/{assembler}/                     # k-mer QV per haplotype
    ├── t2t/{assembler}/                     # telomere-to-telomere contigs
    ├── compleasm/{assembler}/               # BUSCO gene completeness
    ├── merqury/{assembler}/                 # k-mer QV (Illumina)
    └── haplotype_switch/{assembler}/{pstools,yak_trioeval}/
```

Key files:

- **Filtered assembly**: `{sample}.hap1.filt.fa`, `{sample}.hap2.filt.fa`, `{sample}.filt.fa` (combined), plus `{sample}.hap{1,2}.ref.table` (contig→chromosome assignment) and `{sample}.hap{1,2}_stats.txt`.
- **Annotation** (BED/GFF/GTF, mostly bgzipped): Liftoff genes, TRF-mod tandem repeats, dna-nn alpha-satellite, RepeatMasker (`*.rmsk`, `*.LINE1`), SEDEF segmental duplications, CenSat (`*.cenSat`, `*.active.centromeres`), and chain files in both directions.
- **Evaluation summaries**: `flagger/*/summary_flagger_results.txt`, `inspector/*/summary_results.txt`, `nucflag/*/summary_results.txt`, `yak/*.qv.txt`, `t2t/t2t_contigs_hap{1,2}.txt`, `compleasm/summary_results.txt`, `merqury/out.qv`.

---

## Repository layout

```
.
├── set_sample_sheet.py          # Adds one validated row to the sample sheet
├── setup_workflow.py            # Generates config.yaml + run_workflow.sh
├── download_reference.sh        # Downloads + formats reference/annotation files
├── download_compleasm_db.sh     # Downloads the compleasm BUSCO lineage (placement disabled)
├── docs/
│   └── TUTORIAL.md              # Step-by-step end-to-end walkthrough
├── config/
│   ├── config.yaml              # config (created from template)
│   └── samples.tsv.template     # Sample sheet template
├── images/
│   └── pull_image.sh            # Pulls every required Singularity image
├── profile/
│   ├── slurm/                   # Starter Snakemake profile for SLURM
│   └── sge/                     # Starter Snakemake profile for UGE/SGE
└── workflow/
    ├── Snakefile                # Targets: all (default), assembly, annotation, evaluation
    ├── schemas/                 # config + sample sheet validation schemas
    ├── rules/
    │   ├── commons.smk          # sample loading, run_modules / read-type helpers
    │   ├── process.smk          # includes all rule modules
    │   ├── reads/               # read preparation (BAM→FASTQ, concatenation)
    │   ├── assembly/            # assembly.smk (hifiasm/verkko modes) + filter.smk
    │   ├── annotation/          # chain_files, liftoff, trf_mod, dna_nn,
    │   │                        #   repeatmasker, segdup, censat
    │   └── evaluation/          # alignment, flagger, inspector, nucflag, yak,
    │                            #   merqury, count_t2t, compleasm, haplotype_switch
    └── scripts/                 # assembly/ annotation/ evaluation/ helper scripts
```
