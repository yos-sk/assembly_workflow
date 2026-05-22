# Assembly Workflow

A Snakemake workflow for genome assembly generation, comprehensive annotation, and quality evaluation.

## Workflow Overview

This workflow consists of three main modules that can be run independently or in combination:

### Assembly Module

1. **Hifiasm** - Phased assembly using HiFi reads (supports Hi-C and trio modes)
2. **Verkko** - Hybrid assembly using HiFi and ONT reads (supports Hi-C, Pore-C, and trio modes)
3. **Assembly Filtering** - Filter assembly contigs by length and quality

### Annotation Module

1. **Chain Files** - Create chain files for coordinate conversion between assemblies and references (CHM13, GRCh38)
2. **Liftoff** - Gene annotation transfer from GRCh38 using Liftoff
3. **TRF-mod** - Tandem repeat annotation
4. **DNA-NN** - Alpha satellite annotation using DNA-NN
5. **RepeatMasker** - Comprehensive repeat annotation
6. **Segmental Duplications (Sedef)** - Segmental duplication detection
7. **CenSat** - Centromeric satellite annotation

### Evaluation Module

1. **Read Alignment** - Align HiFi/ONT reads to assemblies (prerequisite for Flagger/NucFlag)
2. **Flagger** - Misassembly detection using HiFi and ONT read coverage
3. **Inspector** - Structural and small-scale error detection
4. **Nucflag** - Nucleotide-level misassembly detection
5. **Merqury** - k-mer based quality value (QV) estimation
6. **YAK** - Base-level accuracy estimation
7. **T2T** - Telomere-to-telomere contig identification
8. **Compleasm** - BUSCO gene completeness assessment
9. **PSTools** - Pairwise synteny analysis
10. **Summary Table** - Integrated assembly quality metrics

**Important**: Flagger and NucFlag require read alignments for error detection. The workflow automatically aligns HiFi/ONT reads to assemblies when you provide FASTQ files. You don't need to provide pre-aligned BAM files.

## Directory Structure

```
.
├── setup_workflow.py            # Generates config.yaml + run_workflow.sh
├── config/
│   ├── samples.tsv              # Sample sheet (created from template)
│   └── samples.tsv.template     # Sample sheet template
├── images/
│   └── pull_image.sh            # Pulls every required singularity image
├── profile/
│   ├── slurm/                   # Starter snakemake profile for SLURM
│   └── sge/                     # Starter snakemake profile for UGE/SGE
├── workflow/
│   ├── Snakefile                # Main workflow file
│   ├── schemas/
│   │   ├── config.schema.yaml   # Config validation schema
│   │   └── samples.schema.yaml  # Sample sheet validation schema
│   ├── rules/
│   │   ├── commons.smk          # Common functions and sample loading
│   │   ├── assembly/
│   │   │   ├── hifiasm.smk      # Hifiasm assembly rules
│   │   │   ├── verkko.smk       # Verkko assembly rules
│   │   │   └── filter.smk       # Assembly filtering rules
│   │   ├── annotation/
│   │   │   ├── chain_files.smk  # Chain file generation
│   │   │   ├── liftoff.smk      # Gene annotation
│   │   │   ├── trf_mod.smk      # Tandem repeats
│   │   │   ├── dna_nn.smk       # Alpha satellites
│   │   │   ├── repeatmasker.smk # Repeat annotation
│   │   │   ├── segdup.smk       # Segmental duplications
│   │   │   └── censat.smk       # Centromeric satellites
│   │   └── evaluation/
│   │       ├── alignment.smk    # Read alignment
│   │       ├── flagger.smk      # Flagger error detection
│   │       ├── inspector.smk    # Inspector error detection
│   │       ├── nucflag.smk      # NucFlag error detection
│   │       ├── merqury.smk      # Merqury QV estimation
│   │       ├── yak.smk          # YAK quality assessment
│   │       ├── t2t.smk          # T2T contig identification
│   │       ├── compleasm.smk    # Gene completeness
│   │       └── pstools.smk      # Pairwise synteny
│   └── scripts/
│       ├── assembly/            # Assembly scripts
│       ├── annotation/          # Annotation scripts
│       └── evaluation/          # Evaluation scripts
└── README.md
```

### Output Directory Structure

```
{output.base}/
└── {sample}/
    ├── assembly/
    │   ├── {assembler}/              # Raw assemblies
    │   └── filter/{assembler}/       # Filtered assemblies
    ├── annotation/
    │   ├── trf_mod/{assembler}/
    │   ├── dna_nn/{assembler}/
    │   ├── repeatmasker/{assembler}/
    │   ├── chain_files/{assembler}/
    │   ├── liftoff/{assembler}/
    │   ├── segdup/{assembler}/
    │   └── censat/{assembler}/
    └── evaluation/
        ├── alignment/{assembler}/    # Read alignments (BAM files)
        │   ├── hifi/                 # HiFi read alignments
        │   └── ont/                  # ONT read alignments
        ├── flagger/{assembler}/
        │   ├── hifi/                 # Flagger with HiFi
        │   └── ont/                  # Flagger with ONT
        ├── nucflag/{assembler}/
        ├── inspector/{assembler}/
        ├── merqury/{assembler}/
        ├── yak/{assembler}/
        ├── t2t/{assembler}/
        ├── compleasm/{assembler}/
        └── pstools/{assembler}/
```

## Prerequisites

- **Snakemake** (>= 7.0)
- **Singularity / Apptainer** — every per-tool dependency runs inside a container
- **Python 3** with `pyyaml` (for `setup_workflow.py`)
- **cookiecutter** *(optional — only needed if you generate a cluster profile from a template; see Setup step 2)*

All per-tool dependencies (Hifiasm, Verkko, RepeatMasker, Flagger, …) are shipped as singularity images and pulled by `images/pull_image.sh`. Nothing else needs to be installed on the host.

## Setup

### 1. Pull singularity images

All tool containers are listed in `images/pull_image.sh` and stored as `images/<image-key>.sif`. The image keys match the keys consumed by `config["images"][...]` in the workflow rules, so once they sit in one directory with these names, `setup_workflow.py --images-dir images` (step 3) wires everything automatically.

```bash
bash images/pull_image.sh                  # pull missing images
bash images/pull_image.sh --force          # re-pull everything
bash images/pull_image.sh hifiasm yak      # pull selected keys only
```

### 2. (Cluster only) Set up a snakemake profile via cookiecutter

Skip this for local runs. On a cluster you have two options:

**Bundled starter profiles** under `profile/`: `profile/slurm/` and `profile/sge/` are minimal templates wired to `cluster-generic`. Customize queue/partition/account flags in their `*_submit.sh` scripts. See `profile/README.md` for details.

**Cookiecutter** (community-maintained, more complete):

```bash
pip install cookiecutter
# SLURM
template="gh:Snakemake-Profiles/slurm"
# UGE / SGE
template="gh:Snakemake-Profiles/sge.git"

cookiecutter \
    --output-dir profile \
    $template
```

Pass the resulting directory to `setup_workflow.py --profile <path>` in step 3.

### 3. Sample sheet → config + runner script

Create your sample sheet from the template, then run `setup_workflow.py` to generate both `config/config.yaml` and a runner script `run_workflow.sh`.

```bash
cp config/samples.tsv.template config/samples.tsv
# edit config/samples.tsv with your samples (see columns below)

python setup_workflow.py \
    --samplesheet config/samples.tsv \
    --chm13 /path/to/chm13.fa \
    --grch38 /path/to/GRCh38.fa \
    --images-dir images \
    --profile profile/slurm        # omit for local execution
```

This writes:

- `config/config.yaml` — main snakemake config (use `--output` to change the path)
- `run_workflow.sh` — runner with all flags baked in (use `--runner` to change)

`python setup_workflow.py --help` lists every flag (per-rule resources, per-image overrides, TRF/filter parameters, etc.).

#### Sample sheet example

```tsv
sample  assembler    sex     run_modules           assembly_mode  hap1_assembly         hap2_assembly        hifi_fastq       ont_fastq        hic_r1          hic_r2          ont_platform
HG002   hifiasm_hic  male    all                   hifiasm_hic                                               /data/hifi.fq    /data/ont.fq     /data/hic_R1.fq /data/hic_R2.fq
HG003   verkko       female  annotation,evaluation                /data/HG003.hap1.fa   /data/HG003.hap2.fa  /data/hifi.fq    /data/ont.fq                                     ONT-R10
```

#### Required Columns:
- `sample`: Sample identifier
- `assembler`: Assembler name (e.g., hifiasm_hic, verkko, hifiasm_trio, verkko_porec)
- `sex`: Sample sex (male/female) - affects Y chromosome processing

#### Module Control:
- `run_modules`: Modules to execute (comma-separated or "all")
  - `all`: Run assembly, annotation, and evaluation
  - `assembly,annotation`: Run assembly and annotation only
  - `annotation`: Run annotation only (requires existing assemblies)
  - `evaluation`: Run evaluation only (requires existing assemblies)

#### Assembly Configuration (for assembly generation):
- `assembly_mode`: Assembly strategy (hifiasm_hic, hifiasm_trio, verkko_hic, verkko_porec, verkko_trio)
- `hifi_fastq`: HiFi reads (required for assembly)
- `ont_fastq`: ONT reads (required for Verkko)
- `hic_r1`, `hic_r2`: Hi-C reads (required for *_hic modes)
- `porec_fastq`: Pore-C reads (required for verkko_porec)
- `pat_r1`, `pat_r2`: Paternal reads (required for *_trio modes)
- `mat_r1`, `mat_r2`: Maternal reads (required for *_trio modes)

#### Using Existing Assemblies:
- `hap1_assembly`: Path to haplotype 1 assembly FASTA (if not generating)
- `hap2_assembly`: Path to haplotype 2 assembly FASTA (if not generating)

#### Evaluation Data:
- `hifi_fastq`: HiFi reads (required for Flagger, NucFlag, Inspector, YAK)
- `ont_fastq`: ONT reads (optional, for Flagger ONT mode and Inspector)
- `illumina_r1`, `illumina_r2`: Illumina reads (optional, for Merqury)
- `ont_platform`: ONT platform (ONT-R9 or ONT-R10, default: ONT-R10)

**Important**:
- For evaluation, provide FASTQ files, not BAM files. The workflow automatically aligns reads to assemblies.
- Flagger and NucFlag require `hifi_fastq` even when using existing assemblies.

## Usage

### Quick Start

```bash
# 1. Pull singularity images
bash images/pull_image.sh

# 2. (Cluster) Generate a snakemake profile via cookiecutter, or use profile/slurm.

# 3. Create samples.tsv and generate config + runner
cp config/samples.tsv.template config/samples.tsv
# edit config/samples.tsv with your samples
python setup_workflow.py \
    --samplesheet config/samples.tsv \
    --chm13 /path/to/chm13.fa \
    --grch38 /path/to/GRCh38.fa \
    --images-dir images \
    --profile profile/slurm   # omit for local execution

# 4. Run
./run_workflow.sh
```

### Modular Execution

The workflow supports modular execution controlled by the `run_modules` column in `samples.tsv`:

#### Scenario 1: Full workflow (Assembly + Annotation + Evaluation)
```tsv
sample  assembler    sex   run_modules  assembly_mode  hifi_fastq     ont_fastq     hic_r1         hic_r2
HG002   hifiasm_hic  male  all          hifiasm_hic    /data/hifi.fq  /data/ont.fq  /data/hic_R1.fq /data/hic_R2.fq
```

#### Scenario 2: Annotation of existing assemblies
```tsv
sample  assembler    sex   run_modules  hap1_assembly        hap2_assembly
HG002   hifiasm_hic  male  annotation   /data/HG002.hap1.fa  /data/HG002.hap2.fa
```

#### Scenario 3: Evaluation of existing assemblies
```tsv
sample  assembler  sex   run_modules  hap1_assembly        hap2_assembly        hifi_fastq     ont_fastq
HG002   verkko     male  evaluation   /data/HG002.hap1.fa  /data/HG002.hap2.fa  /data/hifi.fq  /data/ont.fq
```

**Note**: For evaluation, you must provide `hifi_fastq` (required for Flagger/NucFlag alignment).

#### Scenario 4: Assembly + Evaluation (skip annotation)
```tsv
sample  assembler      sex   run_modules           assembly_mode  hifi_fastq     ont_fastq     porec_fastq
HG003   verkko_porec   male  assembly,evaluation   verkko_porec   /data/hifi.fq  /data/ont.fq  /data/porec.fq
```


## Output Files

For each sample and assembler combination, the workflow generates outputs in `{output.base}/{sample}/`:

### Assembly Module Outputs

#### Raw Assemblies (assembly/{assembler}/)
- **Hifiasm**: `{sample}.asm.hic.hap1.p_ctg.fa`, `{sample}.asm.hic.hap2.p_ctg.fa`
- **Verkko**: `assembly.haplotype1.fasta`, `assembly.haplotype2.fasta`

#### Filtered Assemblies (assembly/filter/{assembler}/)
- `{sample}.hap1.filt.fa` - Filtered haplotype 1 assembly
- `{sample}.hap2.filt.fa` - Filtered haplotype 2 assembly
- `{sample}.filt.fa` - Combined filtered assembly
- `{sample}.hap1.ref.table` - Reference alignment table
- `{sample}_stats.txt` - Assembly statistics

### Annotation Module Outputs

#### Chain Files
- `{sample}_to_chm13.chain` - Assembly to CHM13 coordinate conversion
- `{sample}_to_GRCh38.chain` - Assembly to GRCh38 coordinate conversion
- `chm13_to_{sample}.chain` - CHM13 to assembly coordinate conversion
- `GRCh38_to_{sample}.chain` - GRCh38 to assembly coordinate conversion

#### Liftoff
- `{sample}.Ensembl_GRCh38.liftoff.bed.gz` - Gene annotations in BED format
- `{sample}.Ensembl_GRCh38.liftoff.gff.gz` - Gene annotations in GFF format
- `{sample}.Ensembl_GRCh38.liftoff.gtf.gz` - Gene annotations in GTF format

#### TRF-mod
- `{sample}.trf-mod.bed` - Tandem repeat annotations

#### DNA-NN
- `{sample}.hap1_dna-brnn.bed.gz` - Alpha satellite annotations (haplotype 1)
- `{sample}.hap2_dna-brnn.bed.gz` - Alpha satellite annotations (haplotype 2)

#### RepeatMasker
- `{sample}.rmsk.bed.gz` - All repeat annotations
- `{sample}.simple_repeats.bed.gz` - Simple repeat annotations
- `{sample}.LINE1.bed.gz` - LINE1 element annotations

#### CenSat
- `{sample}.cenSat.bed.gz` - Centromeric satellite annotations
- `{sample}.SatelliteStrand.bed.gz` - Satellite strand information
- `{sample}.active.centromeres.bed.gz` - Active centromere annotations
- `{sample}.sorted.resolved_overlaps.bed.gz` - Resolved overlapping annotations

### Evaluation Module Outputs

#### Read Alignments (evaluation/alignment/{assembler}/)
- `hifi/{sample}_hifi.bam` - HiFi reads aligned to assembly
- `hifi/{sample}_hifi.bam.bai` - BAM index
- `ont/{sample}_ont.bam` - ONT reads aligned to assembly (if ONT reads provided)
- `ont/{sample}_ont.bam.bai` - BAM index

#### Flagger (evaluation/flagger/{assembler}/)
- `hifi/final_flagger_prediction.bed` - Misassembly predictions from HiFi reads
- `hifi/summary_flagger_results.txt` - Summary statistics
- `ont/final_flagger_prediction.bed` - Misassembly predictions from ONT reads (if ONT reads provided)
- `ont/summary_flagger_results.txt` - Summary statistics

#### NucFlag (evaluation/nucflag/{assembler}/)
- `nucflag_misassembly.txt` - Nucleotide-level misassembly predictions
- `summary_results.txt` - Summary statistics

#### Inspector
- `inspector/HiFi/HP1/small_scale_error.bed` - Small-scale errors (haplotype 1)
- `inspector/HiFi/HP2/small_scale_error.bed` - Small-scale errors (haplotype 2)
- `inspector/HiFi/HP1/structural_error.bed` - Structural errors (haplotype 1)
- `inspector/HiFi/HP2/structural_error.bed` - Structural errors (haplotype 2)
- `inspector/HiFi/summary_results.txt` - Summary statistics

#### YAK
- `yak/{sample}.hap1.pb.yak.qv.txt` - Quality value for haplotype 1
- `yak/{sample}.hap2.pb.yak.qv.txt` - Quality value for haplotype 2

#### T2T
- `t2t/t2t_contigs_hap1.txt` - Telomere-to-telomere contigs (haplotype 1)
- `t2t/t2t_contigs_hap2.txt` - Telomere-to-telomere contigs (haplotype 2)

#### Compleasm
- `compleasm/HP1/summary.txt` - Gene completeness summary (haplotype 1)
- `compleasm/HP2/summary.txt` - Gene completeness summary (haplotype 2)
- `compleasm/summary_results.txt` - Combined summary

#### Merged Errors
- `merge_assemble_error/output/misassembly.intersect.merged.hap1.bed.gz` - Merged error regions (haplotype 1)
- `merge_assemble_error/output/misassembly.intersect.merged.hap2.bed.gz` - Merged error regions (haplotype 2)

#### Summary Table
- `summary_table/assembly_summary_stats.txt` - Integrated assembly quality metrics

