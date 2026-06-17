#!/usr/bin/env python3

import sys

def is_hap1(contig: str) -> bool:
    # PanSN-renamed contigs are {sample}#{hap}#{chrom}; the haplotype is the
    # second '#'-separated field. Fall back to legacy hifiasm/verkko/trio names.
    parts = contig.split("#")
    if len(parts) >= 3:
        return parts[1] == "1"
    return contig.startswith(("haplotype1", "h1tg", "pat"))

def parse_nucflag_results(nucflag_file: str) -> dict:
    '''
    NucFlag (v0.3.3) flag category (https://github.com/logsdon-lab/NucFlag/wiki)

    - MISJOIN
      - Drop in first most common base coverage or a coverage gap.
      - This region has minimal to no reads supporting it or is a scaffold.
      - Can overlap region with secondary base coverage.
    - COLLAPSE
      - Collapse with no variants.
    - COLLAPSE_VAR
      - Collapse with variants. Overlaps region with high secondary base coverage.
    - COLLAPSE_OTHER
      - Region with high het ratio.
    - HET
      - Possible heterozygous (het) site.
      - Determined by the het ratio, the coverage of the second most common base divided by the first most common base coverage plus the second most common base coverage.
    '''
    # This category is for v0.2.5
    #out_hp1 = {"MISJOIN": [0, 0], "COLLAPSE": [0, 0], "COLLAPSE_VAR": [0, 0], "GAP": [0, 0], "HET": [0, 0], "ERROR": [0, 0]}
    #out_hp2 = {"MISJOIN": [0, 0], "COLLAPSE": [0, 0], "COLLAPSE_VAR": [0, 0], "GAP": [0, 0], "HET": [0, 0], "ERROR": [0, 0]}

    out_hp1 = {"MISJOIN": [0, 0], "COLLAPSE": [0, 0], "COLLAPSE_VAR": [0, 0], "COLLAPSE_OTHER": [0, 0], "HET": [0, 0]}
    out_hp2 = {"MISJOIN": [0, 0], "COLLAPSE": [0, 0], "COLLAPSE_VAR": [0, 0], "COLLAPSE_OTHER": [0, 0], "HET": [0, 0]}

    with open(nucflag_file, "r") as f:
        for line in f:
            items = line.rstrip("\n").split("\t")
            if is_hap1(items[0]):
                out_hp1[items[3]][0] += 1
                out_hp1[items[3]][1] += int(items[2]) - int(items[1])
            else:
                out_hp2[items[3]][0] += 1
                out_hp2[items[3]][1] += int(items[2]) - int(items[1])

    return out_hp1, out_hp2
 
def main():
    sample = sys.argv[1]
    assembler = sys.argv[2]
    nucflag_results = sys.argv[3]

    header = "Sample\tAssembler\tHaplotype\tMisjoin (n)\tMisjoin (bp)\tCollapse (n)\tCollapse (bp)\tCollapse VAR (n)\tCollapse VAR (bp)\t" + \
              "Region with high heterozygous ratio (n)\t Region with high heterozygous ratio (bp)\tPossible heterozygous (n)\tPossible heterogyzous (bp)" 
    print(header)

    summary1, summary2 = parse_nucflag_results(nucflag_results)
    misjoin_n = summary1["MISJOIN"][0]
    misjoin_bp = summary1["MISJOIN"][1]
    collapse_n = summary1["COLLAPSE"][0]
    collapse_bp = summary1["COLLAPSE"][1]
    collapse_var_n = summary1["COLLAPSE_VAR"][0]
    collapse_var_bp = summary1["COLLAPSE_VAR"][1]
    collapse_other_n = summary1["COLLAPSE_OTHER"][0]
    collapse_other_bp = summary1["COLLAPSE_OTHER"][1]
    het_n = summary1["HET"][0]
    het_bp = summary1["HET"][1]

    output = f"{sample}\t{assembler}\t{1}\t{misjoin_n}\t{misjoin_bp}\t{collapse_n}\t{collapse_bp}\t{collapse_var_n}\t{collapse_var_bp}\t{collapse_other_n}\t{collapse_other_bp}\t{het_n}\t{het_bp}"
    print(output)

    misjoin_n = summary2["MISJOIN"][0]
    misjoin_bp = summary2["MISJOIN"][1]
    collapse_n = summary2["COLLAPSE"][0]
    collapse_bp = summary2["COLLAPSE"][1]
    collapse_var_n = summary2["COLLAPSE_VAR"][0]
    collapse_var_bp = summary2["COLLAPSE_VAR"][1]
    collapse_other_n = summary2["COLLAPSE_OTHER"][0]
    collapse_other_bp = summary2["COLLAPSE_OTHER"][1]
    het_n = summary2["HET"][0]
    het_bp = summary2["HET"][1]

    output = f"{sample}\t{assembler}\t{2}\t{misjoin_n}\t{misjoin_bp}\t{collapse_n}\t{collapse_bp}\t{collapse_var_n}\t{collapse_var_bp}\t{collapse_other_n}\t{collapse_other_bp}\t{het_n}\t{het_bp}"
    print(output)
 
if __name__ == "__main__":
    main()
     
