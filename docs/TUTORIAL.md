# Tutorial — GIAB HG008 (Normal)

A hands-on, end-to-end walkthrough on **real data**: the normal sample of the
[Cancer Genome in a Bottle](https://www.nist.gov/programs-projects/cancer-genome-bottle) matched tumor–normal pair **HG008** (donor is **female**,
XX). Two independent paths are provided:

- **[Part A](#part-a--assemble-hg008-n-from-reads)** — generate a phased
  assembly from raw reads (HiFi + ultra-long ONT + Hi-C), then annotate and
  evaluate it. This is the full pipeline and a **large** job.
- **[Part B](#part-b--annotate--evaluate-the-published-assembly)** — skip
  generation and run only **annotation + evaluation** on the *published* HG008
  normal hifiasm/verkko assembly. Much lighter; a good first run.

If this is your first time, **start with Part B** — it downloads ~1.7 GB of
FASTA instead of hundreds of GB of reads and finishes far sooner, while still
exercising annotation and evaluation. Then come back to Part A.

> **Reference vs. tutorial.** This is the guided path. For the full option
> reference (every sample-sheet column, every `setup_workflow.py` flag, the
> complete output tree) see the [README](../README.md).

Run every command from the **repository root** unless stated otherwise. All
tutorial downloads, references, and results live under a single `tutorial/`
directory created here, so they stay separate from the workflow code — make sure
it has plenty of free disk:

```bash
mkdir -p tutorial
```

---

## Before you start

Install the prerequisites from the [README](../README.md#prerequisites)
(Snakemake, Singularity/Apptainer). 

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

The workflow needs a set of reference and annotation files: the two genome
FASTAs (CHM13v2.0, GRCh38), used by assembly filtering, annotation, and the T2T
check, plus four annotation files (CHM13 CenSat BED, GRCh38 centromeres, GRCh38
GRC exclusions, Ensembl 112 GTF) consumed by the annotation module. The repo
ships a helper that downloads and formats all of them into `reference/` (these
are reused across runs, so they live outside `tutorial/` and only need
downloading once):

```bash
bash download_reference.sh reference
```

Record the resulting paths in variables — the `setup_workflow.py` commands in
Parts A and B reference them:

```bash
CHM13=reference/chm13v2.0_maskedY_rCRS.fa
GRCH38=reference/GRCh38.d1.vd1.fa
CHM13_SAT=reference/chm13v2.0_censat_v2.1.bed
GRCH38_CENT=reference/centromeres.txt.gz
GRCH38_EXCL=reference/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed
GRCH38_GTF=reference/Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf
```

The **compleasm** evaluation also needs a BUSCO lineage database
(`primates_odb10`). The helper downloads it from BUSCO and lays it out the way
compleasm expects:

```bash
bash download_compleasm_db.sh reference/mb_downloads
COMPLEASM_LIB=reference/mb_downloads
```

> This deliberately fetches the lineage directly instead of using
> `compleasm download`, whose placement-file step is currently broken upstream
> ([compleasm #61](https://github.com/huangnengCSU/compleasm/issues/61)). The
> workflow runs compleasm with an explicit `-l primates_odb10`, so the lineage
> dataset alone is sufficient.

### Step 1 — Pull the container images

```bash
cd images
bash pull_image.sh        # pulls every image not already present
cd ..
```

### Step 2 — (Cluster only) Snakemake profile

Skip for local runs. On an HPC scheduler:

```bash
template="gh:Snakemake-Profiles/slurm"     # or .../sge
cookiecutter --output-dir profile $template
```

See the [README Setup step 2](../README.md#2-cluster-only-snakemake-profile)
for recommended answers (notably `use_singularity = True`, `use_conda = False`).
It produces `profile/<name>/`, passed to `setup_workflow.py --profile` below.

> All HG008 inputs below are hosted on the GIAB FTP
> (`https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/`).
> The commands set `FTP` to that base path.

```bash
FTP=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab
```

---

## Part A — Assemble HG008-N from reads

This reproduces (with this workflow's parameters) the *normal full* hifiasm
assembly: phased with Hi-C, ultra-long ONT added via `--ul`. Inputs map to the
`hifiasm_hic` mode plus the `ont_ul` column.

> ⚠️ **This is a big job.** The HiFi BAMs alone are ~150 GB, plus ONT and Hi-C
> reads; total downloads are several hundred GB. Generating the assembly needs a
> large-memory HPC node (hundreds of GB RAM) and many hours. Make sure you have
> the disk, memory, and time before starting. **Part B is the lightweight
> alternative.**

### A1 — Download the reads

```bash
mkdir -p "tutorial/data/reads/hifi" "tutorial/data/reads/ont" "tutorial/data/reads/hic"

# HiFi (PacBio Revio, unaligned BAM — the workflow converts BAM→FASTQ).
# 1 pancreatic + 2 duodenal runs (~150 GB total).
wget -P "tutorial/data/reads/hifi" \
  "$FTP/PacBio_Revio_20240125/HG008-N-P_PacBio-Revio_m84039_240114_032308_s2.hifi_reads.bc2006.bam"
wget -P "tutorial/data/reads/hifi" \
  "$FTP/BCM_Revio_20240313/HG008-N-D_ubams/m84059_240304_183205_s3.hifi_reads.bam"
wget -P "tutorial/data/reads/hifi" \
  "$FTP/BCM_Revio_20240313/HG008-N-D_ubams/m84059_240304_203144_s4.hifi_reads.bam"

# Ultra-long ONT (≥25 kb, dorado-called). 4 duodenal + 3 pancreatic files.
ONT_DIR="$FTP/Northeastern_ONT-std_20240422"
for f in \
  03_13_24_R1041_GIAB_Duodenum.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz \
  03_13_24_R1041_GIAB_Duodenum_2.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz \
  03_13_24_R1041_GIAB_Duodenum_3.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz \
  03_13_24_R1041_GIAB_Duodenum_4.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz \
  03_13_24_R1041_GIAB_Normal_Pancreas.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz \
  03_13_24_R1041_GIAB_Normal_Pancreas_2.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz \
  03_13_24_R1041_GIAB_Normal_Pancreas_3.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz ; do
  wget -P "tutorial/data/reads/ont" "$ONT_DIR/$f"
done

# Hi-C (Arima, Illumina 2×150).
wget -P "tutorial/data/reads/hic" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"
```

### A2 — Build the sample sheet

Pass the read files (comma-separated for the multi-file columns). The Hi-C reads
make `set_sample_sheet.py` infer `assembly_mode = hifiasm_hic`; `--sex female`
makes the filter step drop chrY from the reference.

```bash
HIFI=$(ls tutorial/data/reads/hifi/*.bam | paste -sd, -)
ONTUL=$(ls tutorial/data/reads/ont/*.fastq.gz | paste -sd, -)

python3 set_sample_sheet.py --sample HG008N --sex female --assembler hifiasm \
    --run-modules all \
    --hifi "$HIFI" \
    --ont-ul "$ONTUL" \
    --hic-r1 "tutorial/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
    --hic-r2 "tutorial/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"
```

Confirm the inferred row (expect `assembly_mode=hifiasm_hic`):

```bash
column -t -s$'\t' config/samples.tsv
```

### A3 — Generate config + runner (with assembly generation)

Include `--with-assembly` so the runner's default target includes the
assembly-generation step:

```bash
python3 setup_workflow.py \
    --samplesheet config/samples.tsv \
    --chm13 "$CHM13" \
    --grch38 "$GRCH38" \
    --chm13-satellite "$CHM13_SAT" \
    --grch38-centromeres "$GRCH38_CENT" \
    --grch38-exclusions "$GRCH38_EXCL" \
    --grch38-gtf "$GRCH38_GTF" \
    --compleasm-library "$COMPLEASM_LIB" \
    --images-dir images \
    --output-dir tutorial/output \
    --with-assembly \
    --profile profile/slurm        # omit this line for local execution
```

### A4 — Dry run, then run

```bash
./run_workflow.sh -n     # preview the jobs (hifiasm, filter, annotation, flagger, …)
./run_workflow.sh        # execute
```

### A6 — Outputs

Results land under the working directory set above (`tutorial/output`):

```text
tutorial/output/HG008N/
├── assembly/filter/hifiasm/HG008N.hap{1,2}.filt.fa        # filtered, renamed contigs
├── annotation/.../hifiasm/                                  # genes, repeats, satellites, …
└── evaluation/summary_table/hifiasm/assembly_summary_stats.txt   # ← start here
```

> **Caveat — not identical to the published assembly.** The GIAB normal assembly
> was built with extra hifiasm options (`--dual-scaf`, `--telo-m CCCTAA`,
> `--ul-cut`, `--ul-rate`) that this workflow does not pass. Expect a comparable
> but not bit-identical result; the goal here is to exercise the pipeline on real
> data, not to reproduce the published FASTA exactly.

---

## Part B — Annotate & evaluate the published assembly

Here we skip generation and feed the **published** HG008 normal hifiasm
haplotypes to the annotation and evaluation modules. This is the fast path.

### B1 — Download the published assembly

```bash
mkdir -p "tutorial/data/published"
ASM="$FTP/analysis/Harvard_Cheng_hifiasm-assemblies_20240509"
wget -P "tutorial/data/published" \
  "$ASM/HG008.normal.full.asm.hic.hap1.fa.gz" \
  "$ASM/HG008.normal.full.asm.hic.hap2.fa.gz"
```

GIAB also publishes a **Verkko** assembly of the same normal sample. If you would
rather evaluate that one, point `ASM` at the Verkko directory and download its
haplotype FASTAs instead:

```bash
mkdir -p "tutorial/data/published"
ASM="$FTP/analysis/Verkko_assemblies_05162024/HG008_N_asm_hifiherrohic_verkko2.2_20250218"
wget -P "tutorial/data/published" \
  "$ASM/HG008N_verkko-assembly_20250218.haplotype1.fasta.gz" \
  "$ASM/HG008N_verkko-assembly_20250218.haplotype2.fasta.gz"
```

If you choose Verkko, set `--assembler verkko` in B2 and point
`--hap1-assembly`/`--hap2-assembly` at these `.haplotype{1,2}.fasta.gz` files.

The workflow reads gzipped FASTA directly (via `seqtk`), so there is no need to
decompress.

#### A ~30× read set for evaluation (recommended)

The read-independent checks (**T2T**, **compleasm**) and the whole annotation
suite run with no reads at all. To also get the read-based evaluations *without*
Part A's several-hundred-GB read set, download a single ~35× HiFi Revio run plus
the Hi-C pair — enough to drive every HiFi-based evaluation and the phasing QC:

```bash
mkdir -p "tutorial/data/reads/hifi" "tutorial/data/reads/hic"

# HiFi: one Revio run ≈ 35× (≈ 51 GB). Enables Flagger (HiFi), Inspector, NucFlag, yak QV.
wget -P "tutorial/data/reads/hifi" \
  "$FTP/PacBio_Revio_20240125/HG008-N-P_PacBio-Revio_m84039_240114_032308_s2.hifi_reads.bc2006.bam"

# Hi-C (Arima, Illumina 2×150). Enables pstools phasing/switch QC.
wget -P "tutorial/data/reads/hic" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"

# ONT-UL: pseudo ONT-UL from ONT-std run (>25 kb)
mkdir -p "tutorial/data/reads/ont"
ONT_DIR="$FTP/Northeastern_ONT-std_20240422"
wget -P "tutorial/data/reads/ont" \
  "$ONT_DIR/03_13_24_R1041_GIAB_Duodenum.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz" \
  "$ONT_DIR/03_13_24_R1041_GIAB_Normal_Pancreas.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz"
```

### B2 — Build the sample sheet (existing assemblies)

Provide the two haplotypes with `--hap1-assembly`/`--hap2-assembly` and **omit**
`--assembly-mode`; the script then sets `run_modules` for the downstream modules.
We request `evaluation,annotation` explicitly and pass the ~30× read set:

```bash
# Use a fresh sheet (or --force / a different --sample to coexist with Part A).
python3 set_sample_sheet.py --samplesheet config/samples.tsv \
    --sample HG008N_pub --sex female --assembler hifiasm \
    --run-modules evaluation,annotation \
    --hap1-assembly "tutorial/data/published/HG008.normal.full.asm.hic.hap1.fa.gz" \
    --hap2-assembly "tutorial/data/published/HG008.normal.full.asm.hic.hap2.fa.gz" \
    --hifi "tutorial/data/reads/hifi/HG008-N-P_PacBio-Revio_m84039_240114_032308_s2.hifi_reads.bc2006.bam" \
    --ont-ul "tutorial/data/reads/ont/03_13_24_R1041_GIAB_Duodenum.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz,tutorial/data/reads/ont/03_13_24_R1041_GIAB_Normal_Pancreas.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz" \
    --hic-r1 "tutorial/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
    --hic-r2 "tutorial/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"
```

Each read input drives a set of evaluations; drop the read flags entirely to run
only the read-independent **T2T** / **compleasm** checks plus annotation:

| Read input | Unlocks |
|------------|---------|
| `--hifi` (included above) | Flagger (HiFi), Inspector, NucFlag, yak QV |
| `--ont-ul` (optional add) | Flagger (ONT) |
| `--hic-r1/-r2` (included above) | pstools (phasing/switch QC) |

> If you chose the **Verkko** assembly in B1, set `--assembler verkko` and point
> `--hap1-assembly`/`--hap2-assembly` at the `.haplotype{1,2}.fasta.gz` files.

### B3 — Generate config + runner (no assembly generation)

Drop `--with-assembly` — this sample generates nothing, so the default target
(`annotation evaluation`) is exactly what we want:

```bash
python3 setup_workflow.py \
    --samplesheet config/samples.tsv \
    --chm13 "$CHM13" \
    --grch38 "$GRCH38" \
    --chm13-satellite "$CHM13_SAT" \
    --grch38-centromeres "$GRCH38_CENT" \
    --grch38-exclusions "$GRCH38_EXCL" \
    --grch38-gtf "$GRCH38_GTF" \
    --compleasm-library "$COMPLEASM_LIB" \
    --images-dir images \
    --output-dir tutorial/output \
    --profile profile/slurm        # omit for local execution
```

### B4 — Run

```bash
./run_workflow.sh -n     # preview
./run_workflow.sh        # execute
```

### B5 — Read the outputs

```bash
column -t tutorial/output/HG008N_pub/evaluation/summary_table/hifiasm/assembly_summary_stats.txt
```

One row per haplotype: contig count, total length, N50, max contig, QV
(if reads given), error-free %, compleasm completeness, and the **T2T contig
count**. The `t2t/hifiasm/t2t_contigs_hap{1,2}.txt` files list the T2T contigs
(passing per-chromosome concordance thresholds); `*_candidates.txt` is the
unfiltered candidate list. See the [README Outputs](../README.md#outputs) for
the complete tree.

---
