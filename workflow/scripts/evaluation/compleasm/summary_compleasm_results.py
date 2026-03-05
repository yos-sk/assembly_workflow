#!/usr/bin/env python3

import sys

def parse_compleasm_summary(compleasm_summary: str) -> None:
    flagment_n = 0
    flagment_bp = 0
    with open(compleasm_summary, "r") as f:
        for line in f:
            if line[0] == "#": continue

            items = line.rstrip("\n").split(",")
            if line[0] == "M":
                print(items[1], items[0][2:-1], sep="\t")
            elif line[0] == "F":
                flagment_n += int(items[1])
                flagment_bp += float(items[0][2:-1])
            elif line[0] == "I":
                print(flagment_n + int(items[1]), flagment_bp +  float(items[0][2:-1]), sep="\t", end="\t")
            elif line[0] != "N":
                print(items[1], items[0][2:-1], sep="\t", end = "\t")

def main():
    sample = sys.argv[1]
    assembler = sys.argv[2]
    haplotype = sys.argv[3]
    compleasm_summary = sys.argv[4]

    header = "Sample\tAssembler\tHaplotype\tSingle copy complete genes (n)\tSingle copy complete genes (%)\tDuplicated complete genes (n)\tDuplicated complete genes (%)\t" + \
             "Fragmented genes (n)\tFragmented genes (%)\tMissing genes (n)\tMissing genes (%)"
    print(header)
    print(sample, assembler, haplotype, sep="\t", end = "\t")
    parse_compleasm_summary(compleasm_summary)

if __name__ == "__main__":
    main()
