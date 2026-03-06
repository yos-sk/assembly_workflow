# Assembly Workflow Dockerfiles

This directory contains Dockerfiles for all tools used in the assembly workflow, organized by module.

## Directory Structure

```
Dockerfile/
├── assembly/           # Assembly tools
│   ├── hifiasm/       # Hifiasm assembler
│   ├── merqury/       # Merqury QV estimation
│   ├── verkko/        # Verkko assembler
│   └── yak/           # YAK k-mer counter
├── annotation/         # Annotation tools
│   ├── censat/        # Centromeric satellite annotation (censat_gaps, censat_create_annotations)
│   ├── chaintools/    # Liftover chain file generation
│   ├── dna_nn/        # DNA-NN + filter_assembly (dna-brnn, minimap2, samtools, bedtools, fastq_checker)
│   ├── liftoff/       # Gene annotation liftover
│   ├── sedef/         # Segmental duplication detection (sedef, seqtk)
│   ├── tetools/       # RepeatMasker / TE annotation
│   └── TRF-mod/       # Tandem repeat annotation
└── evaluation/         # Evaluation tools
    ├── alignment/     # Read alignment (minimap2, samtools) — also used for bam_to_fastq
    ├── compleasm/     # Gene completeness assessment
    ├── count_t2t/     # T2T contig counting (mashmap)
    ├── flagger/       # Coverage-based error detection
    ├── inspector/     # Structural error detection
    ├── nucflag/       # Nucleotide-level error detection
    └── pstools/       # Pairwise synteny analysis
```

## Singularity Pull Commands

### Reads Module

```bash
# BAM to FASTQ conversion (uses alignment image)
singularity pull alignment-v2.28.sif docker://yosakam2/minimap2:v2.28
```

### Assembly Module

```bash
# Hifiasm
singularity pull hifiasm-v0.25.0.sif docker://yosakam2/hifiasm:v0.25.0

# Verkko
singularity pull verkko-v2.2.1.sif docker://yosakam2/verkko:v2.2.1

# YAK
singularity pull yak-v0.1.sif docker://yosakam2/yak:v0.1

# Merqury
singularity pull merqury-1ad7c32.sif docker://yosakam2/merqury:1ad7c32
```

### Annotation Module

```bash
# Liftoff
singularity pull liftoff-1.6.3.sif docker://yosakam2/liftoff:1.6.3

# Chaintools
singularity pull chaintools-2a3b47e.sif docker://yosakam2/chaintools:2a3b47e

# RepeatMasker (TEtools)
singularity pull tetools-1.88.5.sif docker://yosakam2/tetools:1.88.5

# TRF-mod
singularity pull trf-mod-3e891db.sif docker://yosakam2/trf-mod:3e891db

# DNA-NN / filter_assembly
singularity pull dna-nn-v0.1.sif docker://yosakam2/dna-nn:v0.1

# Sedef
singularity pull sedef-latest.sif docker://yosakam2/sedef:latest

# CenSat (censat_gaps, censat_create_annotations)
singularity pull censat_tools-v0.1.sif docker://yosakam2/censat_tools:v0.1

# CenSat (AlphaSat HMMER, rDNA annotation) — external image
singularity pull alphasat_hmmer-latest.sif docker://juklucas/alphasat_hmmer@sha256:7210a50bc6a99a8beea374f689753e2e6d16b02dc60b400b40694a9ca6ce2489

# CenSat (alphaSat summarize) — external image
singularity pull alphasat_summarize-latest.sif docker://juklucas/alphasat_summarize@sha256:bab2062491c68c0f4c793193c2d3db4d3a301ad041d5d2d863d7978e6fe6d687

# CenSat (HSat2 and HSat3) — external image
singularity pull identify_hsat2and3-latest.sif docker://juklucas/identify_hsat2and3@sha256:f5ed821c44c6167c84c3691dd0bc9dd049ed1dd4a2d1146f2ae58a02c41b8958

# CenSat (RepeatMasker output processing) — external image
singularity pull rm2bed-latest.sif docker://humanpangenomics/rm2bed:latest
```

### Evaluation Module

```bash
# Alignment (minimap2, samtools)
singularity pull alignment-v2.28.sif docker://yosakam2/minimap2:v2.28

# Flagger
singularity pull flagger-v1.1.0.sif docker://yosakam2/flagger:v1.1.0

# Inspector
singularity pull inspector-v1.3.sif docker://yosakam2/inspector:v1.3

# NucFlag
singularity pull nucflag-v0.3.3.sif docker://yosakam2/nucflag:v0.3.3

# Merqury
singularity pull merqury-1ad7c32.sif docker://yosakam2/merqury:1ad7c32

# Compleasm
singularity pull compleasm-v0.2.6.sif docker://yosakam2/compleasm:0.2.6

# MashMap (T2T count)
singularity pull mashmap-v3.1.3.sif docker://yosakam2/mashmap:v3.1.3

# PSTools
singularity pull pstools-v0.2a3.sif docker://yosakam2/pstools:v0.2a3

# Bedtools (merge_assembly_errors) — external image
singularity pull bedtools_v2.31.0.sif docker://biocontainers/bedtools:v2.31.0
```

## Tool Versions

| Module     | Tool              | Version   | Docker Image                        | Dockerfile         |
|------------|-------------------|-----------|-------------------------------------|--------------------|
| Assembly   | Hifiasm           | v0.25.0   | `yosakam2/hifiasm:v0.25.0`          | assembly/hifiasm   |
| Assembly   | Verkko            | v2.2.1    | `yosakam2/verkko:v2.2.1`            | assembly/verkko    |
| Assembly   | YAK               | v0.1      | `yosakam2/yak:v0.1`                 | assembly/yak       |
| Assembly   | Merqury           | 1ad7c32   | `yosakam2/merqury:1ad7c32`          | assembly/merqury   |
| Annotation | Liftoff           | 1.6.3     | `yosakam2/liftoff:1.6.3`            | annotation/liftoff |
| Annotation | Chaintools        | 2a3b47e   | `yosakam2/chaintools:2a3b47e`       | annotation/chaintools |
| Annotation | TEtools           | 1.88.5    | `yosakam2/tetools:1.88.5`           | annotation/tetools |
| Annotation | TRF-mod           | 3e891db   | `yosakam2/trf-mod:3e891db`          | annotation/TRF-mod |
| Annotation | DNA-NN / filter   | v0.1      | `yosakam2/dna-nn:v0.1`              | annotation/dna_nn  |
| Annotation | Sedef             | latest    | `yosakam2/sedef:latest`             | annotation/sedef   |
| Annotation | CenSat tools      | v0.1      | `yosakam2/censat_tools:v0.1`        | annotation/censat  |
| Evaluation | Minimap2/Samtools | v2.28     | `yosakam2/minimap2:v2.28`           | evaluation/alignment |
| Evaluation | Flagger           | v1.1.0    | `yosakam2/flagger:v1.1.0`           | evaluation/flagger |
| Evaluation | Inspector         | v1.3      | `yosakam2/inspector:v1.3`           | evaluation/inspector |
| Evaluation | NucFlag           | v0.3.3    | `yosakam2/nucflag:v0.3.3`           | evaluation/nucflag |
| Evaluation | Compleasm         | 0.2.6     | `yosakam2/compleasm:0.2.6`          | evaluation/compleasm |
| Evaluation | MashMap           | v3.1.3    | `yosakam2/mashmap:v3.1.3`           | evaluation/count_t2t |
| Evaluation | PSTools           | v0.2a3    | `yosakam2/pstools:v0.2a3`           | evaluation/pstools |

## Notes

- **CenSat alphasat / rDNA / hsat / rm2bed**: 外部 image を使用（`juklucas/` および `humanpangenomics/`）
- **Bedtools** (`merge_assembly_errors` rule): 外部 image を使用
- **DNA-NN image** (`yosakam2/dna-nn:v0.1`) は `dna_nn` rule と `filter_assembly` rule の両方で使用
- **Alignment image** (`yosakam2/minimap2:v2.28`) は `alignment` rule と `bam_to_fastq` rule の両方で使用
- **Compleasm lineage databases**: ワークフロー実行時に `config["tools"]["compleasm_library"]` で指定
