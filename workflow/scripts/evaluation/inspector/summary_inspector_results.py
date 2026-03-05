#!/usr/bin/env python3

import sys

def parse_structural_error(structural_error_file: str) -> dict:
    out = {"Expansion": 0, "Collapse": 0, "HaplotypeSwitch": 0, "Inversion": 0}
    with open(structural_error_file, "r") as f:
        for i, line in enumerate(f):
            if i == 0: continue
            items = line.rstrip("\n").split("\t")
            if items[4] == "HaplotypeSwitch":
                starts = items[1].split(";")
                ends = items[2].split(";")
                sizes = items[5].split(";")

                out[items[4]] += int(ends[0]) - int(starts[0])
                out[items[4]] += int(sizes[1])

            elif items[4] == "Collapse":
                max_size = 0
                sizes = items[5].split(";")
                for i, size in enumerate(sizes):
                    if i == 0:
                        max_size = int(size[5:])
                    else:
                        if max_size < int(size):
                            max_size = int(size)
                out[items[4]] = max_size

            else:
                out[items[4]] += int(items[2]) - int(items[1])

    return out


def parse_summary_file(input_summary_file: str) -> dict:
    out = dict()
    with open(input_summary_file, "r") as f:
        for line in f:
            items = line.rstrip("\n").split("\t")
            if items[0] == "Total length":
                out["Total_length"] = int(items[1])
            if items[0] == "Mapping rate /%":
                out["Mapping_rate"] = items[1]

            if items[0] == "Split-read rate /%":
                out["Split-read_rate"] = items[1]

            if items[0] == "Depth":
                out["Depth"] = f"{float(items[1]):.2f}"

            if items[0] == "Expansion":
                out["Expansion"] = items[1]

            if items[0] == "Collapse":
                out["Collapse"] = items[1]

            if items[0] == "Haplotype switch":
                out["Haplotype_switch"] = items[1]

            if items[0] == "Inversion":
                out["Inversion"] = items[1]

            if items[0] == "Small-scale assembly error /per Mbp":
                out["Small-scale_error_rate"] = f"{float(items[1]):.2f}"

            if items[0] == "Base substitution":
                out["substitution"] = items[1]

            if items[0] == "Small-scale expansion":
                out["Small-scale_expansion"] = items[1]

            if items[0] == "Small-scale collapse":
                out["small-scale_collapse"] = items[1]

            if items[0] == "QV":
                out["QV"] = f"{float(items[1]):.2f}"

            if "Genome Coverage /%" in items[0]:
                out["Genome_coverage"] = f"{float(items[0][19:]) * 100:.2f}"
    
    return out

def main():
    sample = sys.argv[1]
    assembler = sys.argv[2]
    haplotype = sys.argv[3]
    data_type = sys.argv[4]
    summary_file = sys.argv[5]
    structural_error_file = sys.argv[6]

    summary = parse_summary_file(summary_file)
    st_error = parse_structural_error(structural_error_file) 

    header = "Sample\tAssembler\tHaplotype\tData type\tMapping rate (%)\tSplit-read rate (%)\t" + \
             "Depth\tStructural error total (n)\tExpansion (n)\tExpansion (bp)\t" + \
             "Collapse (n)\tCollapse (bp)\tHaplotype switch (n)\tHaplotype switch (bp)\t" + \
             "Inversion (n)\tInversion (bp)\t" + \
             "Small-scale assembly error per Mbp\tBase substitution (n)\tSmall-scale expansion (n)\t" + \
             "Small-scale collapse (n)\tQV\tGenome Coverage (%)"
    print(header)
    total_bp = summary["Total_length"]
    mapping_rate = summary["Mapping_rate"]
    split_read_rate = summary["Split-read_rate"]
    depth = summary["Depth"]
    expansion = summary["Expansion"]
    expansion_bp = st_error["Expansion"]
    #expansion_rate = f"{expansion_bp * 100 / total_bp:.2f}"
    collapse = summary["Collapse"]
    collapse_bp = st_error["Collapse"]
    #collapse_rate = f"{collapse_bp * 100 / total_bp:.2f}"
    hap_switch = summary["Haplotype_switch"]
    hap_switch_bp = st_error["HaplotypeSwitch"]
    #hap_switch_rate = f"{hap_switch_bp * 100 / total_bp:.2f}"
    inversion = summary["Inversion"]
    inversion_bp = st_error["Inversion"]
    #inversion_rate = f"{inversion_bp * 100 / total_bp:.2f}"
    total = int(expansion) + int(collapse) + int(hap_switch) + int(inversion)
    small_scale_rate = summary["Small-scale_error_rate"]
    substitution = summary["substitution"]
    small_scale_expansion = summary["Small-scale_expansion"]
    small_scale_collapse = summary["small-scale_collapse"]
    qv = summary["QV"]
    coverage = summary["Genome_coverage"]
    output = f"{sample}\t{assembler}\t{haplotype}\t{data_type}\t{mapping_rate}\t{split_read_rate}\t" + \
             f"{depth}\t{total}\t{expansion}\t{expansion_bp}\t{collapse}\t{collapse_bp}\t{hap_switch}\t{hap_switch_bp}\t" + \
             f"{inversion}\t{inversion_bp}\t{small_scale_rate}\t{substitution}\t{small_scale_expansion}\t{small_scale_collapse}\t{qv}\t{coverage}"
    print(output)

if __name__ == "__main__":
    main()
