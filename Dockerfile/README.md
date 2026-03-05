# Assembly Workflow Dockerfiles

This directory contains Dockerfiles for all tools used in the assembly workflow, organized by module.

## Directory Structure

```
Dockerfile/
├── base/              # Common bioinformatics tools
├── assembly/          # Assembly tools
│   ├── hifiasm/      # Hifiasm assembler
│   ├── verkko/       # Verkko assembler
│   └── yak/          # YAK k-mer counter
├── annotation/        # Annotation tools
│   ├── liftoff/      # Gene annotation transfer
│   ├── tetools/      # RepeatMasker and TE annotation
│   ├── chaintools/   # Liftover chain file generation
│   ├── censat/       # Centromeric satellite annotation
│   ├── dna_nn/       # DNA-NN alpha satellite detection
│   └── sedef/        # Segmental duplication detection
└── evaluation/        # Evaluation tools
    ├── flagger/      # Coverage-based error detection
    ├── nucflag/      # Nucleotide-level error detection
    ├── inspector/    # Structural error detection
    ├── merqury/      # K-mer based QV estimation
    ├── compleasm/    # Gene completeness assessment
    ├── mashmap/      # Fast approximate alignment
    ├── pstools/      # Pairwise synteny analysis
    └── yak/          # QV assessment
```

## Building Docker Images

### Base Image

Build the base image first, as other images may depend on common tools:

```bash
cd Dockerfile/base
docker build -t assembly-workflow/base:latest .
```

### Assembly Module

```bash
# Hifiasm
singulairty pull hifiasm-v0.25.0.sif docker://yosakam2/hifiasm:v0.25.0

# Verkko
singulairty pull verkko-v2.2.1.sif docker://yosakam2/verkko:v2.2.1

# YAK
singulairty pull yak-v0.1.sif docker://yosakam2/yak:v0.1

# MERQURY
```

### Annotation Module

```bash
# Liftoff
singularity pull yosakam2/liftoff:v1.6.3 .

# Chaintools
cd Dockerfile/annotation/chaintools
docker build -t assembly-workflow/chaintools:latest .

# CenSat
## For AlphaSat HMMER annotation and rDNA annotation
singularity pull alphasat_hmmer-latest.sif docker://juklucas/alphasat_hmmer@sha256:7210a50bc6a99a8beea374f689753e2e6d16b02dc60b400b40694a9ca6ce2489
## For Create alphaSat BED
singularity pull alphasat_summarize-latest.sif docker://juklucas/alphasat_summarize@sha256:bab2062491c68c0f4c793193c2d3db4d3a301ad041d5d2d863d7978e6fe6d687
## For HSat2 and HSat3 annotation
singularity pull identify_hsat2and3-latest.sif docker://juklucas/identify_hsat2and3@sha256:f5ed821c44c6167c84c3691dd0bc9dd049ed1dd4a2d1146f2ae58a02c41b8958
## For RepeatMasker output processing
singularity pull rm2bed-latest.sif humanpangenomics/rm2bed:latest
## For Gap annotation and Create final annotations
cd Dockerfile/annotation/censat
docker build -t assembly-workflow/censat:latest .


# DNA-NN
cd Dockerfile/annotation/dna_nn
docker build -t assembly-workflow/dna-nn:latest .

# Sedef
cd Dockerfile/annotation/sedef
docker build -t assembly-workflow/sedef:latest .

# RepeatMasker
singularity build tetools-v1.88.5.sif docker://tetools:1.88.5
```

### Evaluation Module

```bash
# Flagger
singularity pull flagger-v1.1.0.sif docker://yosakam2/flagger:v1.1.0

# NucFlag
singularity pull nucflag-v0.3.3.sif docker://yosakam2/nucflag:v0.3.3

# Inspector
singularity pull inspector-v1.3.sif docker://yosakam2/inspector:v1.3

# Compleasm
singularity pull compleasm-v0.2.6.sif docker://huangnengcsu/compleasm:v0.2.6

# MashMap
singularity pull mashmap-v3.1.3.sif docker://yosakam2/mashmap:v3.1.3

# pstools
singularity pull pstools-v0.2a3.sif docker://yosakam2/pstools:v0.2a3
docker build -t assembly-workflow/pstools:latest .
```

## Build All Images Script

Create a script to build all images:

```bash
#!/bin/bash
# build_all.sh - Build all Docker images for the assembly workflow

set -e

echo "Building base image..."
docker build -t assembly-workflow/base:latest Dockerfile/base/

echo "Building assembly module images..."
docker build -t assembly-workflow/hifiasm:0.19.9 Dockerfile/assembly/hifiasm/
docker build -t assembly-workflow/verkko:2.1 Dockerfile/assembly/verkko/
docker build -t assembly-workflow/yak:0.1 Dockerfile/assembly/yak/

echo "Building annotation module images..."
docker build -t assembly-workflow/liftoff:latest Dockerfile/annotation/liftoff/
docker build -t assembly-workflow/tetools:1.88.5 Dockerfile/annotation/tetools/
docker build -t assembly-workflow/chaintools:latest Dockerfile/annotation/chaintools/
docker build -t assembly-workflow/censat:latest Dockerfile/annotation/censat/
docker build -t assembly-workflow/dna-nn:latest Dockerfile/annotation/dna_nn/
docker build -t assembly-workflow/sedef:latest Dockerfile/annotation/sedef/

echo "Building evaluation module images..."
docker build -t assembly-workflow/flagger:1.1.0 Dockerfile/evaluation/flagger/
docker build -t assembly-workflow/nucflag:0.3.3 Dockerfile/evaluation/nucflag/
docker build -t assembly-workflow/inspector:1.3 Dockerfile/evaluation/inspector/
docker build -t assembly-workflow/merqury:1.3 Dockerfile/evaluation/merqury/
docker build -t assembly-workflow/compleasm:0.2.6 Dockerfile/evaluation/compleasm/
docker build -t assembly-workflow/mashmap:3.1.3 Dockerfile/evaluation/mashmap/
docker build -t assembly-workflow/pstools:latest Dockerfile/evaluation/pstools/
docker build -t assembly-workflow/yak-eval:0.1 Dockerfile/evaluation/yak/

echo "All images built successfully!"
docker images | grep assembly-workflow
```

Save this as `build_all.sh` and run:

```bash
chmod +x build_all.sh
./build_all.sh
```

## Converting to Singularity

To convert Docker images to Singularity containers:

```bash
# Example for hifiasm
singularity build hifiasm_v0.19.9.sif docker-daemon://assembly-workflow/hifiasm:0.19.9

# For all images
for image in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep assembly-workflow); do
    name=$(echo $image | sed 's|assembly-workflow/||' | tr ':' '_')
    singularity build ${name}.sif docker-daemon://${image}
done
```

## Tool Versions

| Module     | Tool        | Version | Image Tag                           |
|------------|-------------|---------|-------------------------------------|
| Base       | minimap2    | 2.28    | assembly-workflow/base:latest       |
| Base       | samtools    | 1.19.2  | assembly-workflow/base:latest       |
| Base       | htslib      | 1.19.1  | assembly-workflow/base:latest       |
| Assembly   | Hifiasm     | 0.19.9  | assembly-workflow/hifiasm:0.19.9    |
| Assembly   | Verkko      | 2.1     | assembly-workflow/verkko:2.1        |
| Assembly   | YAK         | 0.1     | assembly-workflow/yak:0.1           |
| Annotation | Liftoff     | latest  | assembly-workflow/liftoff:latest    |
| Annotation | TEtools     | 1.88.5  | assembly-workflow/tetools:1.88.5    |
| Annotation | Chaintools  | latest  | assembly-workflow/chaintools:latest |
| Annotation | CenSat      | latest  | assembly-workflow/censat:latest     |
| Annotation | DNA-NN      | latest  | assembly-workflow/dna-nn:latest     |
| Annotation | Sedef       | latest  | assembly-workflow/sedef:latest      |
| Evaluation | Flagger     | 1.1.0   | assembly-workflow/flagger:1.1.0     |
| Evaluation | NucFlag     | 0.3.3   | assembly-workflow/nucflag:0.3.3     |
| Evaluation | Inspector   | 1.3     | assembly-workflow/inspector:1.3     |
| Evaluation | Merqury     | 1.3     | assembly-workflow/merqury:1.3       |
| Evaluation | Compleasm   | 0.2.6   | assembly-workflow/compleasm:0.2.6   |
| Evaluation | MashMap     | 3.1.3   | assembly-workflow/mashmap:3.1.3     |
| Evaluation | PSTools     | latest  | assembly-workflow/pstools:latest    |

## Usage in Snakemake

Update `config.yaml` to use the built images:

```yaml
images:
  base: "docker://assembly-workflow/base:latest"
  hifiasm: "docker://assembly-workflow/hifiasm:0.19.9"
  verkko: "docker://assembly-workflow/verkko:2.1"
  yak: "docker://assembly-workflow/yak:0.1"
  liftoff: "docker://assembly-workflow/liftoff:latest"
  tetools: "docker://assembly-workflow/tetools:1.88.5"
  chaintools: "docker://assembly-workflow/chaintools:latest"
  censat_alphasat: "docker://assembly-workflow/censat:latest"
  censat_hmmer: "docker://assembly-workflow/censat:latest"
  censat_hsat: "docker://assembly-workflow/censat:latest"
  censat_rm2bed: "docker://assembly-workflow/censat:latest"
  censat_summarize: "docker://assembly-workflow/censat:latest"
  dna_nn: "docker://assembly-workflow/dna-nn:latest"
  sedef: "docker://assembly-workflow/sedef:latest"
  flagger: "docker://assembly-workflow/flagger:1.1.0"
  nucflag: "docker://assembly-workflow/nucflag:0.3.3"
  inspector: "docker://assembly-workflow/inspector:1.3"
  merqury: "docker://assembly-workflow/merqury:1.3"
  compleasm: "docker://assembly-workflow/compleasm:0.2.6"
  mashmap: "docker://assembly-workflow/mashmap:3.1.3"
  pstools: "docker://assembly-workflow/pstools:latest"
```

Or for Singularity:

```yaml
images:
  hifiasm: "path/to/hifiasm_0.19.9.sif"
  verkko: "path/to/verkko_2.1.sif"
  # ... etc
```

## Notes

- **TRF-mod**: Not included as a Docker image. Install natively or add to base image.
- **DNA-BRNN model**: Download separately and mount as volume when running.
- **Compleasm lineage databases**: Download separately using `compleasm download`.
- **CenSat HMMER models**: Download from T2T consortium resources.
- **Flagger alpha files**: Download platform-specific alpha files separately.

## Customization

To modify tool versions, edit the respective Dockerfile and rebuild:

```bash
# Example: Update Hifiasm to v0.20.0
cd Dockerfile/assembly/hifiasm
# Edit Dockerfile: change git checkout 0.19.9 to git checkout 0.20.0
docker build -t assembly-workflow/hifiasm:0.20.0 .
```

## Troubleshooting

### Build Failures

1. **Network issues**: Add `--network=host` to docker build
2. **Disk space**: Clean up with `docker system prune -a`
3. **Memory limits**: Increase Docker memory allocation in settings

### Runtime Issues

1. **Permission errors**: Use `--user $(id -u):$(id -g)` when running
2. **Missing files**: Mount volumes with `-v /host/path:/container/path`
3. **Tool not found**: Verify PATH is set correctly in Dockerfile

## Contributing

To add a new tool:

1. Create a new directory under the appropriate module
2. Write a Dockerfile following the existing patterns
3. Test the build and functionality
4. Update this README with the new tool information
5. Add the image to the build script
