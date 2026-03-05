#!/usr/bin/env python3

import sys

def parse_flagger_results(input_results: str) -> dict:
    out = {"hp1": {"Hap": 0, "Err": 0, "Dup": 0, "Col": 0, "Unk": 0}, "hp2": {"Hap": 0, "Err": 0, "Dup": 0, "Col": 0, "Unk": 0}}

    with open(input_results, "r") as f:
        for i, line in enumerate(f):
            if i == 0: continue
            items = line.rstrip("\n").split("\t")
            if items[0].startswith(("haplotype1", "h1tg", "pat")):
                out["hp1"][items[3]] += int(items[2]) - int(items[1])
            else:
                out["hp2"][items[3]] += int(items[2]) - int(items[1])
    
    return out

def main():
    sample = sys.argv[1]
    assembler = sys.argv[2]
    input_results = sys.argv[3]

    summary_results = parse_flagger_results(input_results)

    print("Sample", "Assembler", "Haplotype", "Correctly assembled (bp)", "Correctly assembled (%)", "Low read coverage (bp)", "Low read coverage (%)", "False duplication (bp)", "False duplication (%)", "Haplotype collapsed (bp)", "Haplotype collapsed (%)", "Unknown (bp)", "Unknown (%)", sep="\t")
    hap = summary_results["hp1"]["Hap"]
    err = summary_results["hp1"]["Err"]
    dup = summary_results["hp1"]["Dup"]
    col = summary_results["hp1"]["Col"]
    unk = summary_results["hp1"]["Unk"]
    total = hap + err + dup + col + unk
    print(f"{sample}\t{assembler}\t{1}\t{hap}\t{hap * 100 / total:.2f}\t{err}\t{err * 100 / total:.2f}\t{dup}\t{dup * 100 / total:.2f}\t{col}\t{col * 100 / total:.2f}\t{unk}\t{unk * 100 / total:.2f}")
    hap = summary_results["hp2"]["Hap"]
    err = summary_results["hp2"]["Err"]
    dup = summary_results["hp2"]["Dup"]
    col = summary_results["hp2"]["Col"]
    unk = summary_results["hp2"]["Unk"]
    total = hap + err + dup + col + unk
    print(f"{sample}\t{assembler}\t{2}\t{hap}\t{hap * 100 / total:.2f}\t{err}\t{err * 100 / total:.2f}\t{dup}\t{dup * 100 / total:.2f}\t{col}\t{col * 100 / total:.2f}\t{unk}\t{unk * 100 / total:.2f}")

if __name__ == "__main__":
    main()


