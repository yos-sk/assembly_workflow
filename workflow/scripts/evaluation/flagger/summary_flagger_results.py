#!/usr/bin/env python3

import sys

def is_hap1(contig: str) -> bool:
    # PanSN-renamed contigs are {sample}#{hap}#{chrom}; the haplotype is the
    # second '#'-separated field. Fall back to legacy hifiasm/verkko/trio names.
    parts = contig.split("#")
    if len(parts) >= 3:
        return parts[1] == "1"
    return contig.startswith(("haplotype1", "h1tg", "pat"))

def parse_flagger_results(input_results: str) -> dict:
    out = {"hp1": {"Hap": 0, "Err": 0, "Dup": 0, "Col": 0, "Unk": 0}, "hp2": {"Hap": 0, "Err": 0, "Dup": 0, "Col": 0, "Unk": 0}}

    with open(input_results, "r") as f:
        for i, line in enumerate(f):
            if i == 0: continue
            items = line.rstrip("\n").split("\t")
            hp = "hp1" if is_hap1(items[0]) else "hp2"
            out[hp][items[3]] += int(items[2]) - int(items[1])

    return out

def pct(value: int, total: int) -> float:
    return value * 100 / total if total else 0.0

def format_row(sample: str, assembler: str, hap_index: int, d: dict) -> str:
    hap, err, dup, col, unk = d["Hap"], d["Err"], d["Dup"], d["Col"], d["Unk"]
    total = hap + err + dup + col + unk
    return (f"{sample}\t{assembler}\t{hap_index}\t"
            f"{hap}\t{pct(hap, total):.2f}\t{err}\t{pct(err, total):.2f}\t"
            f"{dup}\t{pct(dup, total):.2f}\t{col}\t{pct(col, total):.2f}\t"
            f"{unk}\t{pct(unk, total):.2f}")

def main():
    sample = sys.argv[1]
    assembler = sys.argv[2]
    input_results = sys.argv[3]

    summary_results = parse_flagger_results(input_results)

    print("Sample", "Assembler", "Haplotype", "Correctly assembled (bp)", "Correctly assembled (%)", "Low read coverage (bp)", "Low read coverage (%)", "False duplication (bp)", "False duplication (%)", "Haplotype collapsed (bp)", "Haplotype collapsed (%)", "Unknown (bp)", "Unknown (%)", sep="\t")
    print(format_row(sample, assembler, 1, summary_results["hp1"]))
    print(format_row(sample, assembler, 2, summary_results["hp2"]))

if __name__ == "__main__":
    main()
