#!/usr/bin/env python3

import sys
import os
import gzip
import csv
import argparse

def _present(path) -> bool:
    """True if an optional input was actually provided and exists on disk.

    Snakemake expands an absent (conditional) input to an empty string, so
    treat ""/"NA"/"-"/missing files as 'not available' -> the column becomes "-".
    """
    return bool(path) and path not in ("NA", "-") and os.path.exists(path)

def parse_assembly_stats(assembly_stats: str) -> dict:
    out = dict()
    with open(assembly_stats, "r") as f:
        for line in f:
            items = line.rstrip("\n").split(" ")
            if items[0][:-1] in ["Total_n", "Total_bp", "N50_bp", "Max_bp"]:
                out[items[0][:-1]] = int(items[-1]) 
    return out

def parse_merqury(merqury: str) -> dict:
    out = dict()
    if not _present(merqury):
        return {"hap1": "-", "hap2": "-", "Both": "-"}

    with open(merqury, "r") as f:
        for line in f:
            items = line.rstrip("\n").split("\t")
            if "hap1" in items[0]:
                out["hap1"] = f"{float(items[3]):.2f}"
            elif "hap2" in items[0]:
                out["hap2"] = f"{float(items[3]):.2f}"
            else:
                out["Both"] = f"{float(items[3]):.2f}"

    return out

def parse_yak(yak: str) -> dict:
    out = ""
    if not _present(yak):
        return "-"

    with open(yak, "r") as f:
        for line in f:
            if not line.startswith("QV"): continue
            items = line.rstrip("\n").split("\t")
            out = f"{float(items[2]):.2f}"

    return out


def parse_error(error_file: str, contig_length: int) -> str:
    if not _present(error_file):
        return "-"
    error_length = 0
    with gzip.open(error_file, "rt") as f:
        for line in f:
            items = line.rstrip("\n").split("\t")
            error_length += int(items[2]) - int(items[1])

    return f"{100 - error_length * 100 / contig_length:.2f}"

def parse_compleasem(compleasm: str) -> str:
    out = ""
    with open(compleasm, "r") as f:
        for line in f:
            if line[0] != "S": continue
            out = line.split(",")[0].split(":")[1][:-1]

    return out

def parse_t2t(t2t: str) -> int:
    # t2t is the already-filtered T2T contigs file (count_t2t.py filter);
    # the threshold logic now lives in count_t2t.py, so just count the rows.
    count = 0
    with open(t2t, "r") as f:
        for line in f:
            if line.strip():
                count += 1
    return count

def load_pstools_result(path: str):
    """Hi-C phasing (pstools phase_error_output.txt): take the last row's
    Switch/Hamming columns, dropping the trailing '%'. Returns (switch, hamming)."""
    switch, hamming = "-", "-"
    with open(path) as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            switch = row["Switch Error Rate"].rstrip("%")
            hamming = row["Hamming Distance"].rstrip("%")
    return switch, hamming


def load_yak_trioeval(paths):
    """Trio phasing (yak trioeval): sum W (switch) and H (hamming) counts over the
    given files (paternal + maternal) and return (switch%, hamming%)."""
    se = sed = he = hed = 0
    for p in paths:
        with open(p) as f:
            for line in f:
                items = line.rstrip("\n").split("\t")
                if items[0] == "W":
                    se += int(items[1]); sed += int(items[2])
                elif items[0] == "H":
                    he += int(items[1]); hed += int(items[2])
    switch = f"{se / sed * 100:.4f}" if sed else "-"
    hamming = f"{he / hed * 100:.4f}" if hed else "-"
    return switch, hamming


def parse_phasing(pstools, trio_pat, trio_mat):
    """Switch/Hamming error: prefer Hi-C (pstools), else trio (yak trioeval),
    else '-'. Returns (switch, hamming) as strings."""
    if _present(pstools):
        return load_pstools_result(pstools)
    trio = [p for p in (trio_pat, trio_mat) if _present(p)]
    if trio:
        return load_yak_trioeval(trio)
    return "-", "-"


def arg_parser():
    parser = argparse.ArgumentParser(prog = "make_summary_table.py",
            description = "Make a summary table of assembly evaluation")

    parser.add_argument("--sample", "-n", type = str,
                        help = "Sample name")

    parser.add_argument("--tool", "-l", type = str,
                        help = "Assembler name")

    parser.add_argument("--assembly_stats_hp1", "-a", type = str,
                        help = "Hap1 assemble stats file")

    parser.add_argument("---assembly_stats_hp2", "-b", type = str,
                        help = "Hap1 assemble stats file")

    parser.add_argument("--merqury", "-c", type = str, default=None,
                        help = "Merqury result file")

    parser.add_argument("--yak_hp1", "-y", type = str,
                        help = "yak hap1 result file")

    parser.add_argument("--yak_hp2", "-z", type = str,
                        help = "yak hap2 result file")

    parser.add_argument("--error_hp1", "-d", type = str,
                        help = "Hap1 miassembly file")
    
    parser.add_argument("--error_hp2", "-e", type = str,
                        help = "Hap2 misassembly file")

    parser.add_argument("--compleasm_hp1", "-f", type = str,
                        help = "Hap1 compleasm file")

    parser.add_argument("--compleasm_hp2", "-g", type = str,
                        help = "Hap2 compleasm file")

    parser.add_argument("--t2t_hp1", "-i", type = str,
                        help = "Hap1 t2t contigs file")

    parser.add_argument("--t2t_hp2", "-j", type = str,
                        help = "Hap2 t2tb contigs file")

    parser.add_argument("--pstools", type = str, default="",
                        help = "pstools phase_error_output.txt (Hi-C switch/hamming)")

    parser.add_argument("--trio-pat", dest="trio_pat", type = str, default="",
                        help = "yak trioeval paternal phasing file (trio)")

    parser.add_argument("--trio-mat", dest="trio_mat", type = str, default="",
                        help = "yak trioeval maternal phasing file (trio)")

    parser.add_argument("--output", "-o", type = str,
                        help = "PATH to output file")
    args = parser.parse_args()

    return args

def main():
    args = arg_parser()

    parsed_assembly_stats_hp1 = parse_assembly_stats(args.assembly_stats_hp1)
    parsed_error_hp1 = parse_error(args.error_hp1, parsed_assembly_stats_hp1["Total_bp"])
    parsed_compleasm_hp1 = parse_compleasem(args.compleasm_hp1)
    parsed_t2t_hp1 = parse_t2t(args.t2t_hp1)
    parsed_yak_hp1 = parse_yak(args.yak_hp1)

    parsed_assembly_stats_hp2 = parse_assembly_stats(args.assembly_stats_hp2)
    parsed_error_hp2 = parse_error(args.error_hp2, parsed_assembly_stats_hp2["Total_bp"])
    parsed_compleasm_hp2 = parse_compleasem(args.compleasm_hp2)
    parsed_t2t_hp2 = parse_t2t(args.t2t_hp2)
    parsed_yak_hp2 = parse_yak(args.yak_hp2)

    parsed_merqury = parse_merqury(args.merqury)

    # Phasing switch/hamming error: assembly-level (same value reported on both
    # haplotype rows). Hi-C (pstools) preferred, else trio (yak trioeval), else "-".
    phasing_switch, phasing_hamming = parse_phasing(args.pstools, args.trio_pat, args.trio_mat)

    total_n = parsed_assembly_stats_hp1["Total_n"]
    total_bp = parsed_assembly_stats_hp1["Total_bp"]
    n50_bp = parsed_assembly_stats_hp1["N50_bp"]
    max_bp = parsed_assembly_stats_hp1["Max_bp"]
    merqury_hp1 = parsed_merqury["hap1"]
    output_hp1 = f"{args.sample}\t{args.tool}\t{1}\t{total_n}\t{total_bp / 1000000000:.2f}\t" + \
                 f"{n50_bp / 1000000:.2f}\t{max_bp / 1000000:.2f}\t{parsed_yak_hp1}\t{merqury_hp1}\t{parsed_error_hp1}\t" + \
                 f"{parsed_compleasm_hp1}\t{parsed_t2t_hp1}\t{phasing_switch}\t{phasing_hamming}"

    total_n = parsed_assembly_stats_hp2["Total_n"]
    total_bp = parsed_assembly_stats_hp2["Total_bp"]
    n50_bp = parsed_assembly_stats_hp2["N50_bp"]
    max_bp = parsed_assembly_stats_hp2["Max_bp"]
    merqury_hp2 = parsed_merqury["hap2"]
    output_hp2 = f"{args.sample}\t{args.tool}\t{2}\t{total_n}\t{total_bp / 1000000000:.2f}\t" + \
                 f"{n50_bp / 1000000:.2f}\t{max_bp / 1000000:.2f}\t{parsed_yak_hp2}\t{merqury_hp2}\t{parsed_error_hp2}\t" + \
                 f"{parsed_compleasm_hp2}\t{parsed_t2t_hp2}\t{phasing_switch}\t{phasing_hamming}"

    header = "\t".join([
        "Sample", "Assembler", "Haplotype",
        "Contigs", "Total_length(Gbp)", "N50(Mbp)", "Max_contig(Mbp)",
        "yak_QV", "Merqury_QV", "Correct_assembly_ratio(%)", "Compleasm_complete(%)", "T2T_contigs",
        "Switch_error(%)", "Hamming_error(%)",
    ])

    with open(args.output, "w") as w:
        print(header, file=w)
        print(output_hp1, file=w)
        print(output_hp2, file=w)

if __name__ == "__main__":
    main()
