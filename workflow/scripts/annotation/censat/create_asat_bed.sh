#!/bin/bash

set -o pipefail
set -e
set -u
set -o xtrace

## Requires: 
# bedtools 
# python3 
# merge_overlaps.py (requires pandas, pybedtools, warnings)

# input bed should be sorted

## Call with 
#  ./create_asat_bed.sh \
#     assembly_AS-HOR-vs-CHM13.bed \
#     assembly_AS-SF-vs-CHM13.bed \
#     output_file_name.bed


## Color scheme for output:
# active 250,0,0
# HOR 255,146,0
# dHOR 153,0,0
# mon 255,204,153


hor_bed=$1
monomeric_bed=$2
out_bed=$3
work_dir=$4

## Needed later in order to call python3 ${SCRIPT_DIR}/merge_overlaps.py
#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


###############################################################################
##                             Create List of HORs                           ##
###############################################################################


## Unique list of HORs is used in order to merge bed regions only within
## the same HOR.

## remove everything after period in 4th column
## So S1C1/5/19H1L.6/4_5-6  --> S1C1/5/19H1L
awk 'BEGIN{OFS="\t"} {split($4, a, "."); $4=a[1]; print}' \
    "$hor_bed" \
    > ${work_dir}/HOR_basenames.bed


# Sort input by fourth column and then by chromosome and start position
sort -k4,4 -k1,1 -k2,2n ${work_dir}/HOR_basenames.bed > ${work_dir}/HOR_basenames_sortbyhor.bed

# Get unique values in the fourth column
unique_values=( $(cut -f4 ${work_dir}/HOR_basenames_sortbyhor.bed | uniq) )


###############################################################################
##                                 Merge HORs                                ##
###############################################################################

## clean up, just in case of rerun (don't print error if it doesn't exist)
rm ${work_dir}/HOR_basenames_merged.bed 2> /dev/null || true

# Merge entries for each unique value separately
for value in ${unique_values[@]}; do
    # merge monomers separated by around two monomers (171 * 2 = 342 --> 350) and 
    # require final size to be at least 5 monomers (171 * 5 = 855 --> 900)
    # then merge any blocks that are separated by LINEs (~6000 --> 6500)
    bedtools merge -c 4 -o distinct -d 350 -i <(grep -Fw $value ${work_dir}/HOR_basenames.bed) \
    | awk '($3-$2) >= 900' >> ${work_dir}/HOR_basenames_merged.bed
done


# Sort  output by chromosome and start position
sort -k1,1 -k2,2n ${work_dir}/HOR_basenames_merged.bed -o ${work_dir}/HOR_basenames_merged_sorted.bed


###############################################################################
##                  Filter Out S4/S5 That Should Be Monomeric                ##
###############################################################################

## Pull just S4/S5 from HOR groupings
grep -E "S4|S5" \
    ${work_dir}/HOR_basenames_merged_sorted.bed \
    > ${work_dir}/HOR_basenames_merged_sorted_S4_S5.bed


## Find units that are larger than 2kb - changed 7/8/24 by HL
## Improve later by actually looking up what the HOR lengths should be
## Just went with something cautious for now...
awk -v OFS='\t' '$3 - $2 <= 2000' \
    ${work_dir}/HOR_basenames_merged_sorted_S4_S5.bed \
    > ${work_dir}/HOR_basenames_merged_sorted_S4_S5_short.bed

## Check how much coverage of HOR annotated monomers each unit has. Remove
## any units that have less than 80% coverage of monomers w/ HOR annotation.
## Future improvement: take into account only coverage outside of LINE elements!
bedtools coverage \
    -a ${work_dir}/HOR_basenames_merged_sorted_S4_S5.bed \
    -b "$hor_bed" \
    | awk '$8 <= .80' \
    > ${work_dir}/HOR_basenames_merged_sorted_S4_S5_sparse.bed

## Combine into one bed then sort
cat \
    ${work_dir}/HOR_basenames_merged_sorted_S4_S5_short.bed \
    ${work_dir}/HOR_basenames_merged_sorted_S4_S5_sparse.bed \
    | awk 'BEGIN{OFS="\t"} {print $1,$2,$3,$4}' \
    | bedtools sort \
    > ${work_dir}/HOR_basenames_merged_sorted_S4_S5_to_remove.bed 



# Can't use bedtools subtract here
grep -v -x \
    -f ${work_dir}/HOR_basenames_merged_sorted_S4_S5_to_remove.bed \
    ${work_dir}/HOR_basenames_merged_sorted.bed \
    | awk 'BEGIN{OFS="\t"} {print $1, $2, $3, $4, "100", ".", $2, $3, "255,255,255"}' \
    | awk 'BEGIN{OFS="\t"} {
            if ($4 ~ /H1L/) {
                $4="active_hor("$4")"
                $9="153,0,0"
            } else if ($4 ~ /d/) {
                $4="dhor("$4")"
                $9="244,146,0"
            } else {
                $4="hor("$4")"
                $9="255,102,0"
            }
            print }' \
    > ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric.bed


###############################################################################
##                      Remove Small HORs In Other HORs                      ##
###############################################################################


# Use bedtools to find regions within other regions
bedtools intersect \
    -a ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric.bed \
    -b ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric.bed \
    -wa -wb \
    | awk 'BEGIN{OFS="\t"} {
        # Calculate the length of each region
        lenA = $3 - $2;
        # lenB = $12 - $11;

        # Check if region A is completely inside region B and is under 5 kbp
        if ($1 == $10 && $2 > $11 && $3 < $12 && lenA < 5000) {
            print $1, $2, $3, $4, $5, $6, $7, $8, $9;
        }
    }' > ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_to_clean.bed

## Actually removed the contained regions
grep -v -x \
    -f ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_to_clean.bed \
    ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric.bed \
    > ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned.bed    


###############################################################################
##                           Merge Overlapping HORs                          ##
###############################################################################

## Look for HORs like hor(S3C1H2-A) and hor(S3C1H2-B) that overlap and combine
## (when neccesary) into hor(S3C1H2-A,B)
python3 /opt/scripts/merge_overlaps.py \
    -i ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned.bed \
    -o ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned_mergeoverlaps.bed

bedtools sort \
    -i ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned_mergeoverlaps.bed \
    > ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned_mergeoverlaps_sorted.bed


###############################################################################
##                               Monomeric                                   ##
###############################################################################


## find monomers that aren't in HORs
bedtools subtract \
    -A \
    -a $monomeric_bed \
    -b ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned_mergeoverlaps_sorted.bed \
    > ${work_dir}/sf_not_in_merged_hor.bed

## Merge across large gaps (LINEs) and add monomeric name and color
bedtools merge \
    -d 6500 \
    -c 4 -o distinct \
    -i ${work_dir}/sf_not_in_merged_hor.bed \
    | awk 'BEGIN{OFS="\t"} {print $1, $2, $3, "mon", "100", ".", $2, $3, "255,204,153"}' \
    > ${work_dir}/merged_mon.bed 



###############################################################################
##                                Merge over LINES                           ##
###############################################################################

bedtools sort -i ${work_dir}/HOR_basenames_merged_sorted_wout_monomeric_cleaned_mergeoverlaps_sorted.bed \
    > ${work_dir}/Summary.sorted.bed
    
# Find the unique bins again 
unique_bins=$(cut -f4 ${work_dir}/Summary.sorted.bed | sort -u)

## clean up, just in case of rerun (don't print error if it doesn't exist)
rm ${work_dir}/Summary_LINEmerged.bed 2> /dev/null || true

# Merge over LINEs 
for value in ${unique_bins[@]}; do
    # merge any blocks that are separated by LINEs (~6000 --> 6500)
    grep -Fw $value ${work_dir}/Summary.sorted.bed \
    | bedtools merge -c 4 -o distinct -d 6500 -i stdin \
    | bedtools sort -i  \
    >> ${work_dir}/Summary_LINEmerged.bed
done

## Subtract mon agains HORS to make sure merged monomers don't span over HORs
bedtools subtract \
    -a ${work_dir}/merged_mon.bed \
    -b ${work_dir}/Summary_LINEmerged.bed \
    | awk 'BEGIN{OFS="\t"} {print $1, $2, $3, "mon", "100", ".", $2, $3, "255,204,153"}' \
    >> ${work_dir}/Summary_LINEmerged.bed


# Fix the labels once again 
cat ${work_dir}/Summary_LINEmerged.bed \
    | awk 'BEGIN{OFS="\t"} {print $1, $2, $3, $4, "100", ".", $2, $3, "255,255,255"}' \
    | awk 'BEGIN{OFS="\t"} {
            if ($4 ~ /H1L/) {
                $9="153,0,0"
            } else if ($4 ~ /d/) {
                $9="255,146,0"
            } else if ($4 ~ /mon/) {
                $9="255,204,153"
            } else {
                $9="255,102,0" 
            }
            print }' \
        | bedtools sort -i \
        > $out_bed

echo ${?}