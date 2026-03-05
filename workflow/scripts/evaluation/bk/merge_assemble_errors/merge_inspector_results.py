#!/usr/bin/env python3

import sys

def parse_inspector_structural_error(ins_struct_error: str, ofile) -> None:

    with open(ins_struct_error, "r") as f:
        for line in f:
            if line[0] == "#": continue
            items = line.rstrip("\n").split("\t")
            haplotype = "haplotype1" if items[0].startswith("h1tg") or items[0].startswith("haplotype1") else "haplotype2"
            if items[4] == "HaplotypeSwitch":
                starts = items[1].split(";")
                ends = items[2].split(";")
                print(items[0], starts[0], ends[0], "HaplotypeSwitchExpansion", sep="\t", file=ofile)
                print(items[0], starts[1], ends[1], "HaplotypeSwitchCollapse", sep="\t", file=ofile)
            else:
                print(items[0], items[1], items[2], items[4], sep="\t", file=ofile)

def parse_inspector_small_error(ins_small_error: str, ofile) -> None:
    
    with open(ins_small_error, "r") as f:
        for line in f:
            if line[0] == "#": continue
            items = line.rstrip("\n").split("\t")
            haplotype = "haplotype1" if "h1tg" in items[0] or "haplotype1" in items[0] else "haplotype2"
            print(items[0], items[1], items[2],  items[7],  sep="\t", file=ofile)


def main():
    ins_small_error_hp1 = sys.argv[1]
    ins_small_error_hp2 = sys.argv[2]
    ins_struct_error_hp1 = sys.argv[3]
    ins_struct_error_hp2 = sys.argv[4]
    output_file = sys.argv[5]

    #print("Contig", "Start", "End", "Tool", "Error", sep="\t")
    with open(output_file, "w") as w:
        parse_inspector_small_error(ins_small_error_hp1, w)
        parse_inspector_structural_error(ins_struct_error_hp1, w)
        parse_inspector_small_error(ins_small_error_hp2, w)
        parse_inspector_structural_error(ins_struct_error_hp2, w)

if __name__ == "__main__":
    main()

