# Tutorial: GIAB HG008 (Normal)

A hands-on, end-to-end walkthrough on **real data**: the normal sample of the
[Cancer Genome in a Bottle](https://www.nist.gov/programs-projects/cancer-genome-bottle)
matched tumor–normal pair **HG008** (donor is **female**, XX). Three independent
parts are provided, from quickest to heaviest:

- **[Part 1 — chr20 quick run](#part-1-chromosome-20-quick-run)** — assemble,
  annotate, and evaluate **chromosome 20 only**. The fastest way to exercise the
  *whole* pipeline (assembly generation included) on a tiny input.
- **[Part 2 — published assembly, evaluation + annotation](#part-2-annotate--evaluate-the-published-assembly)** —
  skip generation and run only **annotation + evaluation** on the *published*
  HG008 normal hifiasm/verkko assembly.
- **[Part 3 — full assembly from reads](#part-3-assemble-hg008-n-from-reads)** —
  generate the whole-genome phased assembly from the full read set, then annotate
  and evaluate. The complete pipeline and a **large** job.

If this is your first time, **start with Part 1** — it downloads only the chr20
slice of the reads and finishes quickly, while still running assembly →
annotation → evaluation exactly as the full pipeline does.

> **Reference vs. tutorial.** This is the guided path. For the full option
> reference (every sample-sheet column, every `setup_workflow.py` flag, the
> complete output tree) see the [README](../README.md).

Run every command from the **repository root** unless stated otherwise. Shared
references live under `reference/`. Each part keeps its downloads and results
under its own directory: `tutorial/chr20/` (Part 1), `tutorial/eval/` (Part 2),
`tutorial/full/` (Part 3).

---

## Before you start

Clone the repository and run every command below from its root:

```bash
git clone https://github.com/yos-sk/assembly_workflow.git
cd assembly_workflow
```

Install the prerequisites from the [README](../README.md#prerequisites)
(Snakemake, Singularity/Apptainer). Part 1 additionally needs **samtools** on the
host to slice chr20 out of the published alignments.

A quick install with [mamba](https://github.com/mamba-org/mamba):

```bash
# Snakemake (+ pyyaml for setup_workflow.py) in a dedicated environment
mamba create -n assembly_workflow -c conda-forge -c bioconda "snakemake>=7,<8" pyyaml samtools

# Singularity/Apptainer — OPTIONAL: skip if you already have it (system install
# or `module load apptainer`/`singularity`); just keep it on PATH. Linux only.
mamba install -n assembly_workflow -c conda-forge apptainer

# cookiecutter (optional, only for generating a cluster profile)
mamba install -n assembly_workflow -c conda-forge cookiecutter

# Activate the environment.
mamba activate assembly_workflow # or just put the env on PATH: export PATH=PATH_to_assembly_workflow_env:$PATH"
```

### References (shared by all parts)

The workflow needs the two genome FASTAs (CHM13v2.0, GRCh38), used by assembly
filtering, annotation, and the T2T check, plus four annotation files (CHM13
CenSat BED, GRCh38 centromeres, GRCh38 GRC exclusions, Ensembl 112 GTF) consumed
by the annotation module. A helper downloads and formats all of them into
`reference/` (reused across runs, so they live outside the per-part directories
and only need downloading once):

```bash
bash download_reference.sh reference
```

Record the resulting paths in variables — the `setup_workflow.py` commands in
every part reference them:

```bash
CHM13=reference/chm13v2.0_maskedY_rCRS.fa
GRCH38=reference/GRCh38.d1.vd1.fa
CHM13_SAT=reference/chm13v2.0_censat_v2.1.bed
GRCH38_CENT=reference/centromeres.txt.gz
GRCH38_EXCL=reference/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed
GRCH38_GTF=reference/Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf
```

The **compleasm** evaluation also needs a BUSCO lineage database
(`primates_odb10`):

```bash
bash download_compleasm_db.sh reference/mb_downloads
COMPLEASM_LIB=reference/mb_downloads
```

> The helper fetches the lineage directly from BUSCO instead of using `compleasm
> download`. compleasm's run path otherwise tries to download BUSCO *placement*
> files and crashes on a recently added `eukaryota_odb12.2.*` entry
> ([compleasm #61](https://github.com/huangnengCSU/compleasm/issues/61)). Since
> placement files are only used for auto-lineage selection — never for an explicit
> `-l primates_odb10` run — the helper strips all `placement_files` rows from the
> local `file_versions.tsv`, so compleasm's placement step becomes a no-op (no
> crash, no download, works offline).

The **CenSat** annotation step needs HMM profiles and HSat k-mer tables, which
are large and not committed to the repo. Fetch them once into the script's `db/`
directory (the annotation scripts expect them there):

```bash
( cd workflow/scripts/annotation/censat/db && bash download.sh )
```

### Step 1. Pull the container images

```bash
cd images
bash pull_image.sh        # pulls every image not already present
cd ..
```

### Step 2. (Cluster only) Snakemake profile

Skip for local runs. On an HPC scheduler:

```bash
template="gh:Snakemake-Profiles/slurm"     # or .../sge
cookiecutter --output-dir profile $template
```

See the [README Setup step 2](../README.md#2-cluster-only-snakemake-profile)
for recommended answers (notably `use_singularity = True`, `use_conda = False`).
It produces `profile/<name>/`, passed to `setup_workflow.py --profile` below.

Then pin each job's `--cores` to the CPUs the scheduler allocates (the profile already
maps each rule's `threads` to `--cpus-per-task` / `-pe`), overriding Snakemake's
`--cores all` — which on clusters that don't bind CPUs can mean the whole node and
oversubscribe. `{exec_job}` ends in `&& exit 0 || exit 1`, so appending after it is a
no-op; capture it, rewrite `--cores all` (Snakemake 7 emits it as `--cores 'all'`),
then run it.

```bash
cat > profile/slurm/slurm-jobscript.sh <<'EOF'
#!/bin/bash
# properties = {properties}
exec_job=$(cat <<'SMK_EXEC_JOB'
{exec_job}
SMK_EXEC_JOB
)
ncores="${{SLURM_CPUS_PER_TASK:-1}}"
exec_job=$(printf '%s' "$exec_job" | sed -E "s/--cores '?all'?/--cores $ncores/")
eval "$exec_job"
EOF
```

For **SGE**, write the same body to `profile/sge/sge-jobscript.sh` with
`SLURM_CPUS_PER_TASK` replaced by `NSLOTS`. Re-apply whenever you regenerate the
profile.

### Shared shell variables

The download/setup commands below use these:

```bash
FTP=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab
SINGBIND="$HOME"   # directory tree to mount into the containers (see note)
```

> **`--singularity-bind`.** Singularity/Apptainer only mounts a default set of
> paths, so inputs outside them are invisible and rules fail to find their files.
> Bind the tree holding your reads, references, and outputs — here everything is
> under `$HOME`, so `SINGBIND="$HOME"` covers it (use a comma-separated list like
> `"/data,/scratch"` otherwise). Omit `--singularity-bind` for local runs.
>
> ⚠️ **HPC caveat.** `set_sample_sheet.py` does **not** resolve symlinks, but on
> many clusters `$HOME` (e.g. `/home/<user>`) is a symlink to physical storage
> like `/lustre/home/<user>`. Check the absolute paths written into the sample
> sheet (`column -t -s$'\t' <sheet>`) and bind whatever prefix they actually show
> — e.g. `SINGBIND="/lustre"` if the rows read `/lustre/home/...`.

> **Re-running `setup_workflow.py`?** It will not overwrite an existing config /
> runner; add `--force` (`-f`) to regenerate them.

---

## Part 1. Chromosome 20 quick run

Assemble, annotate, and evaluate **chr20 only**. Reads are sliced out of the
published CHM13-aligned BAMs, so the inputs are small and the whole pipeline
finishes quickly — ideal for a first end-to-end run. There are no Hi-C reads
here, so `set_sample_sheet.py` infers the plain `hifiasm` mode (hifiasm's own
phasing into hap1/hap2; pstools phasing-QC simply does not run).

### 1.1. Download the chr20 reads

`samtools view ... chr20` extracts the chr20 primary alignments (`-F 2308` drops
unmapped/secondary/supplementary records); the workflow later converts BAM→FASTQ.

```bash
mkdir -p "tutorial/chr20/data/reads/hifi" "tutorial/chr20/data/reads/ont"

# HiFi (chr20 slice of the CHM13-aligned Revio BAMs): pancreatic 35x + duodenal 68x.
samtools view -Shb -F 2308 \
    "$FTP/PacBio_Revio_20240125/HG008-N-P_PacBio-HiFi-Revio_20240125_35x_CHM13v2.0.bam" chr20 \
> tutorial/chr20/data/reads/hifi/HG008N.chr20.hifi_1.bam
samtools view -Shb -F 2308 \
    "$FTP/BCM_Revio_20240313/HG008-N-D_PacBio-HiFi-Revio_20240313_68x_CHM13v2.0.bam" chr20 \
> tutorial/chr20/data/reads/hifi/HG008N.chr20.hifi_2.bam

# Ultra-long ONT (chr20 slice, ≥25 kb): duodenal 13x + pancreatic 20x.
samtools view -Shb -F 2308 \
    "$FTP/Northeastern_ONT-std_20240422/HG008-N-D_CHM13v2.0_ONT-R1041-dorado_0.5.3_5mC_5hmC_13x_gt25kb.bam" chr20 \
> tutorial/chr20/data/reads/ont/HG008N.chr20.ont_1.bam
samtools view -Shb -F 2308 \
    "$FTP/Northeastern_ONT-std_20240422/HG008-N-P_CHM13v2.0_ONT-R1041-dorado_0.5.3_5mC_5hmC_20x_gt25kb.bam" chr20 \
> tutorial/chr20/data/reads/ont/HG008N.chr20.ont_2.bam
```

### 1.2. Subset the references to chr20

The reference-using steps (filter, chain files, Liftoff, Inspector, T2T) only
need chr20 here. Slice CHM13, GRCh38, and the GTF down to chr20 into a separate
`reference/chr20/` (the shared full `reference/` stays intact). The GTF **must**
match the chr20-only GRCh38 FASTA, or Liftoff fails on genes whose chromosome is
absent. The CenSat/centromere/exclusion BEDs and the compleasm DB stay as-is —
only their chr20 rows get used.

```bash
mkdir -p reference/chr20

# Genome FASTAs -> chr20 only. awk keeps the FULL header (incl. AC:/LN:/M5:/AS:
# tags) and needs no .fai; `samtools faidx` would drop everything after the first
# header token. It prints the chr20 header line and every sequence line until the
# next '>'.
awk '/^>/{keep=($1==">chr20")} keep' "$CHM13"  > reference/chr20/chm13.chr20.fa
awk '/^>/{keep=($1==">chr20")} keep' "$GRCH38" > reference/chr20/GRCh38.chr20.fa

# GRCh38 GTF -> chr20 only (keep header lines); consistent with the chr20 FASTA.
awk -F'\t' '$1=="chr20" || /^#/' "$GRCH38_GTF" > reference/chr20/GRCh38.chr20.gtf

# Point the chr20 run at these (BEDs and compleasm DB keep their shared paths).
CHM13_C20=reference/chr20/chm13.chr20.fa
GRCH38_C20=reference/chr20/GRCh38.chr20.fa
GRCH38_GTF_C20=reference/chr20/GRCh38.chr20.gtf
```

### 1.3. Build the sample sheet

No Hi-C/Pore-C/trio reads, so the inferred `assembly_mode` is `hifiasm`.
`set_sample_sheet.py` absolutises the read paths, so relative globs are fine.

```bash
HIFI=$(ls tutorial/chr20/data/reads/hifi/*.bam | paste -sd, -)
ONTUL=$(ls tutorial/chr20/data/reads/ont/*.bam | paste -sd, -)

python3 set_sample_sheet.py --samplesheet config/samples_chr20.tsv \
    --sample HG008N_chr20 --sex female --assembler hifiasm \
    --run-modules all \
    --hifi "$HIFI" \
    --ont-ul "$ONTUL"
```

Confirm the inferred row (expect `assembly_mode=hifiasm`):

```bash
column -t -s$'\t' config/samples_chr20.tsv
```

### 1.4. Generate config + runner

chr20 is ~2% of the genome, so the pipeline's whole-genome resource defaults
(e.g. `censat_alphasat` 56 CPU × 8 G = 448 G, `liftoff` 50 × 8 G = 400 G) are
wildly oversized here and can leave jobs PENDING on a busy cluster. Pass per-rule
`--<rule>-cpus` / `--<rule>-mem-per-cpu` sized to an actual chr20 run (peak RSS
≤ 24 G). The variables below were set in steps 1.1–1.2.

```bash
python3 setup_workflow.py \
    --samplesheet config/samples_chr20.tsv \
    --output config/config_chr20.yaml \
    --runner run_chr20.sh \
    --chm13 "$CHM13_C20" \
    --grch38 "$GRCH38_C20" \
    --chm13-satellite "$CHM13_SAT" \
    --grch38-centromeres "$GRCH38_CENT" \
    --grch38-exclusions "$GRCH38_EXCL" \
    --grch38-gtf "$GRCH38_GTF_C20" \
    --compleasm-library "$COMPLEASM_LIB" \
    --images-dir images \
    --output-dir tutorial/chr20/output \
    --singularity-bind "$SINGBIND" \
    --profile profile/slurm \
    `# read prep`    --prepare-hifi-cpus 8 --prepare-hifi-mem-per-cpu 1G \
                     --prepare-ont-cpus 8 --prepare-ont-mem-per-cpu 1G \
                     --prepare-ont-ul-cpus 8 --prepare-ont-ul-mem-per-cpu 1G \
    `# assembly`     --hifiasm-cpus 16 --hifiasm-mem-per-cpu 3G \
                     --assembly-filter-cpus 4 --assembly-filter-mem-per-cpu 4G \
    `# annotation`   --chain-files-cpus 8 --chain-files-mem-per-cpu 2G \
                     --liftoff-cpus 8 --liftoff-mem-per-cpu 4G \
                     --trf-mod-cpus 1 --trf-mod-mem-per-cpu 8G \
                     --dna-nn-cpus 8 --dna-nn-mem-per-cpu 2G \
                     --repeatmasker-cpus 16 --repeatmasker-mem-per-cpu 2G \
                     --sedef-cpus 8 --sedef-mem-per-cpu 4G \
                     --filter-sedef-cpus 1 --filter-sedef-mem-per-cpu 6G \
    `# censat`       --censat-split-cpus 1 --censat-split-mem-per-cpu 6G \
                     --censat-alphasat-cpus 16 --censat-alphasat-mem-per-cpu 2G \
                     --censat-rdna-cpus 8 --censat-rdna-mem-per-cpu 2G \
                     --censat-gaps-cpus 1 --censat-gaps-mem-per-cpu 4G \
                     --censat-hsat-cpus 1 --censat-hsat-mem-per-cpu 4G \
                     --censat-repeatmasker-cpus 2 --censat-repeatmasker-mem-per-cpu 4G \
                     --censat-create-cpus 1 --censat-create-mem-per-cpu 6G \
                     --censat-create-asat-bed-cpus 1 --censat-create-asat-bed-mem-per-cpu 6G \
    `# evaluation`   --alignment-hifi-cpus 16 --alignment-hifi-mem-per-cpu 2G \
                     --alignment-ont-cpus 16 --alignment-ont-mem-per-cpu 2G \
                     --flagger-cpus 8 --flagger-mem-per-cpu 2G \
                     --inspector-cpus 8 --inspector-mem-per-cpu 4G \
                     --nucflag-cpus 8 --nucflag-mem-per-cpu 3G \
                     --yak-cpus 8 --yak-mem-per-cpu 4G \
                     --compleasm-cpus 8 --compleasm-mem-per-cpu 3G
    # add --force to overwrite an existing config/runner; omit --profile for local runs
```

### 1.5. Dry run, then run

```bash
./run_chr20.sh -n     # preview the jobs (hifiasm, filter, annotation, flagger, …)
./run_chr20.sh        # execute
```

### 1.6. Outputs

```bash
column -t tutorial/chr20/output/HG008N_chr20/evaluation/summary_table/hifiasm/assembly_summary_stats.txt
```

```text
tutorial/chr20/output/HG008N_chr20/
├── assembly/filter/hifiasm/HG008N_chr20.hap{1,2}.filt.fa    # filtered, renamed contigs
├── annotation/.../hifiasm/                                   # genes, repeats, satellites, …
└── evaluation/summary_table/hifiasm/assembly_summary_stats.txt
```

> **Expect chr20-scale numbers.** compleasm completeness will be low (only the
> genes on chr20 are present), and T2T / flagger reflect chr20 alone. That is
> expected — Part 1 is about seeing the pipeline run, not assembly quality.

---

## Part 2. Annotate & evaluate the published assembly

Skip generation and feed the **published** HG008 normal haplotypes to the
annotation and evaluation modules.

### 2.1. Download the published assembly

```bash
mkdir -p "tutorial/eval/data/published"
ASM="$FTP/analysis/Harvard_Cheng_hifiasm-assemblies_20240509"
wget -P "tutorial/eval/data/published" \
  "$ASM/HG008.normal.full.asm.hic.hap1.fa.gz" \
  "$ASM/HG008.normal.full.asm.hic.hap2.fa.gz"
```

GIAB also publishes a **Verkko** assembly of the same normal sample. To evaluate
that one instead, point `ASM` at the Verkko directory:

```bash
mkdir -p "tutorial/eval/data/published"
ASM="$FTP/analysis/Verkko_assemblies_05162024/HG008_N_asm_hifiherrohic_verkko2.2_20250218"
wget -P "tutorial/eval/data/published" \
  "$ASM/HG008N_verkko-assembly_20250218.haplotype1.fasta.gz" \
  "$ASM/HG008N_verkko-assembly_20250218.haplotype2.fasta.gz"
```

If you choose Verkko, set `--assembler verkko` in 2.2 and point
`--hap1-assembly`/`--hap2-assembly` at these `.haplotype{1,2}.fasta.gz` files.
The workflow reads gzipped FASTA directly (via `seqtk`), so there is no need to
decompress.

#### A ~30× read set for evaluation (recommended)

The read-independent checks (**T2T**, **compleasm**) and the whole annotation
suite run with no reads at all. To also get the read-based evaluations *without*
Part 3's several-hundred-GB read set, download a single ~35× HiFi Revio run, the
Hi-C pair, and a couple of ONT files:

```bash
mkdir -p "tutorial/eval/data/reads/hifi" "tutorial/eval/data/reads/hic" "tutorial/eval/data/reads/ont"

# HiFi: one Revio run ≈ 35× (≈ 51 GB). Enables Flagger (HiFi), Inspector, NucFlag, yak QV.
wget -P "tutorial/eval/data/reads/hifi" \
  "$FTP/PacBio_Revio_20240125/HG008-N-P_PacBio-Revio_m84039_240114_032308_s2.hifi_reads.bc2006.bam"

# Hi-C (Arima, Illumina 2×150). Enables pstools phasing/switch QC.
wget -P "tutorial/eval/data/reads/hic" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"

# ONT (≥25 kb), 1 duodenal + 1 pancreatic. Enables Flagger (ONT).
ONT_DIR="$FTP/Northeastern_ONT-std_20240422"
wget -P "tutorial/eval/data/reads/ont" \
  "$ONT_DIR/03_13_24_R1041_GIAB_Duodenum.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz" \
  "$ONT_DIR/03_13_24_R1041_GIAB_Normal_Pancreas.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz"
```

### 2.2. Build the sample sheet (existing assemblies)

Provide the two haplotypes with `--hap1-assembly`/`--hap2-assembly` and **omit**
`--assembly-mode`; the script then sets `run_modules` for the downstream modules.
We request `evaluation,annotation` explicitly and pass the ~30× read set:

```bash
python3 set_sample_sheet.py --samplesheet config/samples_eval.tsv \
    --sample HG008N_pub --sex female --assembler hifiasm \
    --run-modules evaluation,annotation \
    --hap1-assembly "tutorial/eval/data/published/HG008.normal.full.asm.hic.hap1.fa.gz" \
    --hap2-assembly "tutorial/eval/data/published/HG008.normal.full.asm.hic.hap2.fa.gz" \
    --hifi "tutorial/eval/data/reads/hifi/HG008-N-P_PacBio-Revio_m84039_240114_032308_s2.hifi_reads.bc2006.bam" \
    --ont-ul "tutorial/eval/data/reads/ont/03_13_24_R1041_GIAB_Duodenum.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz,tutorial/eval/data/reads/ont/03_13_24_R1041_GIAB_Normal_Pancreas.dorado_0.5.3_5mC_5hmC.longer_than_25kb.fastq.gz" \
    --hic-r1 "tutorial/eval/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
    --hic-r2 "tutorial/eval/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"
```

Each read input drives a set of evaluations; drop the read flags entirely to run
only the read-independent **T2T** / **compleasm** checks plus annotation:

| Read input | Unlocks |
|------------|---------|
| `--hifi` (included above) | Flagger (HiFi), Inspector, NucFlag, yak QV |
| `--ont-ul` (included above) | Flagger (ONT) |
| `--hic-r1/-r2` (included above) | pstools (phasing/switch QC) |

### 2.3. Generate config + runner

The runner defaults to the `all` target, which runs each sample's `run_modules`.
This sample is `evaluation,annotation` with no `assembly_mode`, so only those two
modules run (filtering the supplied haplotypes) — no assembly is generated:

```bash
python3 setup_workflow.py \
    --samplesheet config/samples_eval.tsv \
    --output config/config_eval.yaml \
    --runner run_eval.sh \
    --chm13 "$CHM13" \
    --grch38 "$GRCH38" \
    --chm13-satellite "$CHM13_SAT" \
    --grch38-centromeres "$GRCH38_CENT" \
    --grch38-exclusions "$GRCH38_EXCL" \
    --grch38-gtf "$GRCH38_GTF" \
    --compleasm-library "$COMPLEASM_LIB" \
    --images-dir images \
    --output-dir tutorial/eval/output \
    --singularity-bind "$SINGBIND" \
    --profile profile/slurm        # omit for local execution
```

### 2.4. Run

```bash
./run_eval.sh -n     # preview
./run_eval.sh        # execute
```

### 2.5. Read the outputs

```bash
column -t tutorial/eval/output/HG008N_pub/evaluation/summary_table/hifiasm/assembly_summary_stats.txt
```

One row per haplotype: contig count, total length, N50, max contig, QV
(if reads given), error-free %, compleasm completeness, and the **T2T contig
count**. The `t2t/hifiasm/t2t_contigs_hap{1,2}.txt` files list the T2T contigs
(passing per-chromosome concordance thresholds); `*_candidates.txt` is the
unfiltered candidate list. See the [README Outputs](../README.md#outputs) for
the complete tree.

---

## Part 3. Assemble HG008-N from reads

The complete pipeline on the full read set: a Hi-C-phased whole-genome assembly
(`hifiasm_hic` mode, ultra-long ONT added via `--ul`), then annotation and
evaluation.

> ⚠️ **This is a big job.** The HiFi BAMs alone are ~150 GB, plus ONT and Hi-C
> reads; total downloads are several hundred GB. Generating the assembly needs a
> large-memory HPC node (hundreds of GB RAM) and many hours. Make sure you have
> the disk, memory, and time before starting.

### 3.1. Download the reads

```bash
mkdir -p "tutorial/full/data/reads/hifi" "tutorial/full/data/reads/ont" "tutorial/full/data/reads/hic"

# HiFi (PacBio Revio, unaligned BAM). 1 pancreatic + 2 duodenal runs (~150 GB total).
wget -P "tutorial/full/data/reads/hifi" \
  "$FTP/PacBio_Revio_20240125/HG008-N-P_PacBio-Revio_m84039_240114_032308_s2.hifi_reads.bc2006.bam"
wget -P "tutorial/full/data/reads/hifi" \
  "$FTP/BCM_Revio_20240313/HG008-N-D_ubams/m84059_240304_183205_s3.hifi_reads.bam"
wget -P "tutorial/full/data/reads/hifi" \
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
  wget -P "tutorial/full/data/reads/ont" "$ONT_DIR/$f"
done

# Hi-C (Arima, Illumina 2×150).
wget -P "tutorial/full/data/reads/hic" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
  "$FTP/Arima_HiC-ILMN_20240112/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"
```

### 3.2. Build the sample sheet

The Hi-C reads make `set_sample_sheet.py` infer `assembly_mode = hifiasm_hic`;
`--sex female` makes the filter step drop chrY from the reference.

```bash
HIFI=$(ls tutorial/full/data/reads/hifi/*.bam | paste -sd, -)
ONTUL=$(ls tutorial/full/data/reads/ont/*.fastq.gz | paste -sd, -)

python3 set_sample_sheet.py --samplesheet config/samples_full.tsv \
    --sample HG008N --sex female --assembler hifiasm \
    --run-modules all \
    --hifi "$HIFI" \
    --ont-ul "$ONTUL" \
    --hic-r1 "tutorial/full/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R1.fastq.gz" \
    --hic-r2 "tutorial/full/data/reads/hic/HG008-N-D_HiC-Arima_ILMN-2x150_R2.fastq.gz"
```

Confirm the inferred row (expect `assembly_mode=hifiasm_hic`):

```bash
column -t -s$'\t' config/samples_full.tsv
```

### 3.3. Generate config + runner

The runner defaults to the `all` target, which runs each sample's `run_modules`.
This sample is `all`, so assembly generation, annotation, and evaluation all run:

```bash
python3 setup_workflow.py \
    --samplesheet config/samples_full.tsv \
    --output config/config_full.yaml \
    --runner run_full.sh \
    --chm13 "$CHM13" \
    --grch38 "$GRCH38" \
    --chm13-satellite "$CHM13_SAT" \
    --grch38-centromeres "$GRCH38_CENT" \
    --grch38-exclusions "$GRCH38_EXCL" \
    --grch38-gtf "$GRCH38_GTF" \
    --compleasm-library "$COMPLEASM_LIB" \
    --images-dir images \
    --output-dir tutorial/full/output \
    --singularity-bind "$SINGBIND" \
    --profile profile/slurm        # omit for local execution
```

### 3.4. Dry run, then run

```bash
./run_full.sh -n     # preview the jobs
./run_full.sh        # execute
```

### 3.5. Outputs

```text
tutorial/full/output/HG008N/
├── assembly/filter/hifiasm/HG008N.hap{1,2}.filt.fa          # filtered, renamed contigs
├── annotation/.../hifiasm/                                   # genes, repeats, satellites, …
└── evaluation/summary_table/hifiasm/assembly_summary_stats.txt
```
