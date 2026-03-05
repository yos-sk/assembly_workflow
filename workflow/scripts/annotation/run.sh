#!/bin/bash

set -ex

SAMPLE=$1
ASSEMBLER=$2
HAP1_ASSEMBLY=$3
HAP2_ASSEMBLY=$4
SEX=$5

log=./log/${SAMPLE}_${ASSEMBLER}


# 1. filter assembly contigs
mkdir -p ../output/filter/${ASSEMBLER}/${SAMPLE}
python ./filter/filter_length_assembly.py \
    ${HAP1_ASSEMBLY} \
    ${HAP2_ASSEMBLY} \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa 

~/bin/samtools/samtools-1.17/samtools faidx ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa
~/bin/samtools/samtools-1.17/samtools faidx ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa

singularity exec ~/sandbox/fastq_checker/fastq_checker-v0.3.2b.sif fastq_checker check \
    -i ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa \
    -f fasta \
1>../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1_stats.txt 2>/dev/null

singularity exec ~/sandbox/fastq_checker/fastq_checker-v0.3.2b.sif fastq_checker check \
    -i ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa \
    -f fasta \
1>../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2_stats.txt 2>/dev/null

cat ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa > ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.filt.fa
~/bin/samtools/samtools-1.17/samtools faidx ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.filt.fa

# 2. RepeatMasker
sbatch -J rmsk_${SAMPLE}_${ASSEMBLER} -e ${log}/rmsk.err -o ${log}/rmsk.out ./RepeatMasker/RepeatMasker.sh \
    ${SAMPLE} \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.filt.fa \
    ../output/RepeatMasker/${ASSEMBLER}/${SAMPLE}



# 3. chain-files 
sbatch -J prepare_mask_regions_${SAMPLE}_${ASSEMBLER} -e ${log}/prepare_mask_regions.err -o ${log}/prepare_mask_regions.out ./chain-files/prepare_mask_regions.sh \
    ../../../reference/db/chm13v2.0_censat_v2.1.bed \
    ../../../reference/chm13v2.0_maskedY_rCRS.fa \
    ../../../reference/db/GRCh38_centromeres.txt.gz \
    ../../../reference/db/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed \
    ../../../reference/GRCh38.d1.vd1.fa \
    ../output/chain-files/db \
    ../output/chain-files/db/workspace

JOBID=$(echo $(squeue -noheader --format %i --name prepare_mask_regions_${SAMPLE}_${ASSEMBLER}) | cut -d ' ' -f 2)
sbatch --dependency=afterok:${JOBID} -J make_chain_files_${SAMPLE}_${ASSEMBLER} -e ${log}/make_chain_file.err -o ${log}/make_chain_file.out ./chain-files/make_chain_files.sh \
    ${SAMPLE} \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa \ ${ASSEMBLER} \
    ${SEX} \
    ../output/chain-files/db \
    ../output/chain-files/${ASSEMBLER}/${SAMPLE}/workspace \
    ../output/chain-files/${ASSEMBLER}/${SAMPLE}


# 4. liftoff
sbatch -J liftoff_${SAMPLE}_${ASSEMBLER} -e ${log}/liftoff.err -o ${log}/liftoff.out ./liftoff/liftoff.sh \
    ${SAMPLE} \
    ${ASSEMBLER} \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa \
    ~/bin/minimap2/2.28/minimap2-2.28_x64-linux/minimap2 \
    ${SEX} \
    ../../../reference/GRCh38.d1.vd1.fa \
    ../../../reference/db/Homo_sapiens.GRCh38.Ensembl.112.chr.format.gtf \
    /home/yosakam2/projects/PRCGAP-paper/image/liftoff_latest.sif \
    ../output/liftoff/${ASSEMBLER}/${SAMPLE} \
    ../output/liftoff/${ASSEMBLER}/${SAMPLE}/workspace


# 5. trf-mod
sbatch -J trf-mod_${SAMPLE}_${ASSEMBLER} -e ${log}/trf-mod.err -o ${log}/trf-mod.out ./trf-mod/trf-mod.sh \
    ${SAMPLE} \
    ${ASSEMBLER} \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.filt.fa \
    ../output/trf-mod/${ASSEMBLER}/${SAMPLE}


# 6. dna-nn
sbatch -J dna-nn_${SAMPLE}_${ASSEMBLER} -e ${log}/dna-nn.err -o ${log}/dna-nn.out ./dna-nn/dna-nn.sh \
    ${SAMPLE} \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa \
    ../output/dna-nn/${ASSEMBLER}/${SAMPLE}


# 7. segdup
RMSK_JOBID=$(echo $(squeue -noheader --format %i --name rmsk_${SAMPLE}_${ASSEMBLER}) | cut -d ' ' -f 2)
TRF_JOBID=$(echo $(squeue -noheader --format %i --name trf-mod_${SAMPLE}_${ASSEMBLER}) | cut -d ' ' -f 2)
sbatch --dependency=afterok:${RMSK_JOBID},${TRF_JOBID} -J segdup_${SAMPLE}_${ASSEMBLER} -e ${log}/segdup.err -o ${log}/segdup.out ./segdup/sedef.sh \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa \
    ../output/RepeatMasker/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.rmsk.bed.gz \
    ../output/trf-mod/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.trf-mod.bed \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}/workspace \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}

JOBID=$(echo $(squeue -noheader --format %i --name segdup_${SAMPLE}_${ASSEMBLER}) | cut -d ' ' -f 2)
sbatch --dependency=afterok:${JOBID} -J filter_segdup_${SAMPLE}_${ASSEMBLER} -e ${log}/filter_segdup.err -o ${log}/filter_segdup.out ./segdup/filter_sedef.sh \
    ${SAMPLE} \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}/HP1/final.bed \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}/HP2/final.bed \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}/workspace \
    ../output/segdup/${ASSEMBLER}/${SAMPLE} \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}/workspace/rmsk_hap1.bed \
    ../output/segdup/${ASSEMBLER}/${SAMPLE}/workspace/rmsk_hap2.bed \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap1.filt.fa.fai \
    ../output/filter/${ASSEMBLER}/${SAMPLE}/${SAMPLE}.hap2.filt.fa.fai


