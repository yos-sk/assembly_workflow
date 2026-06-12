#!/usr/bin/env python3

import sys
import argparse

def extract_contigs(input_telo):
    out = list()
    with open(input_telo, "r") as f:
        tmp_flag = dict()
        for line in f:
            items = line.rstrip("\n").split("\t")
            start = int(items[1])
            end = int(items[2])
            contig_end = int(items[3])
            contig = items[0]
            if contig not in tmp_flag:
                tmp_flag[contig] = 0
            if start == 0:
                tmp_flag[contig] += 1
            if end == contig_end:
                tmp_flag[contig] += 1

    for contig in tmp_flag:
        if tmp_flag[contig] == 2:
            out.append(contig)

    return out

def extract_length(intervals: dict):
    '''
    intervals:
        key: chromosome
        value: list of intervals (tuple(start, end))

    return:
        key; chromosome
        value: total length of intervals
    '''

    length = dict()
    for key, value in intervals.items():
        prev_end = 0
        length[key] = 0
        for start, end in sorted(value, key=lambda x: x[0]):
            if prev_end == 0 or prev_end <= start:
                length[key] += end - start
            elif start < prev_end < end:
                length[key] += end - prev_end + 1

            prev_end = end

    return length

def t2t_concord(input_paf, candidate_contigs, out=sys.stdout):
    prev_contig = ""
    ref_length_db = dict()
    t_intervals = dict()
    with open(input_paf, "r") as f:
        for line in f:
            items = line.rstrip("\n").split("\t")
            contig = items[0]
            ref_contig = items[5]
            if ref_contig not in ref_length_db:
                ref_length_db[ref_contig] = int(items[6])
            if contig not in candidate_contigs: continue

            if contig != prev_contig:
                if prev_contig != "":
                    length_dir = extract_length(t_intervals)
                    max_contig = max(length_dir, key=length_dir.get)
                    length = length_dir[max_contig]
                    print(prev_contig, max_contig, length, length / ref_length_db[max_contig], sep="\t", file=out)
                prev_contig = items[0]
                t_intervals = dict()
                t_intervals[ref_contig] = [(int(items[7]), int(items[8]))]
            else:
                if ref_contig in t_intervals:
                    t_intervals[ref_contig].append((int(items[7]), int(items[8])))
                else:
                    t_intervals[ref_contig] = [(int(items[7]), int(items[8]))]

        if prev_contig != "":
            length_dir = extract_length(t_intervals)
            max_contig = max(length_dir, key=length_dir.get)
            length = length_dir[max_contig]
            print(prev_contig, max_contig, length, length / ref_length_db[max_contig], sep="\t", file=out)

def is_t2t(chrom: str, concordance: float) -> bool:
    '''Per-chromosome reference-concordance threshold for calling a candidate T2T.'''
    if chrom == "chr9":
        return concordance > 0.9
    elif chrom == "chrY":
        return concordance > 0.6
    else:
        return concordance > 0.95

def filter_candidates(candidates_file, out=sys.stdout):
    '''Keep candidate contigs whose reference concordance passes is_t2t().'''
    with open(candidates_file, "r") as f:
        for line in f:
            if not line.strip():
                continue
            items = line.rstrip("\n").split("\t")
            chrom = items[1]
            concordance = float(items[3])
            if is_t2t(chrom, concordance):
                print(line.rstrip("\n"), file=out)

def cmd_candidates(args):
    contigs = extract_contigs(args.telo)
    t2t_concord(args.paf, contigs)

def cmd_filter(args):
    filter_candidates(args.candidates)

def main():
    parser = argparse.ArgumentParser(
        prog="count_t2t.py",
        description="Identify telomere-to-telomere (T2T) contigs.")
    sub = parser.add_subparsers(dest="command", required=True)

    p_cand = sub.add_parser(
        "candidates",
        help="List T2T candidate contigs (both telomeres present) with their "
             "best reference chromosome and concordance.")
    p_cand.add_argument("telo", help="seqtk telo output (telo_hap*.tsv)")
    p_cand.add_argument("paf", help="mashmap alignment (APPROX-ALIGN_hap*.paf)")
    p_cand.set_defaults(func=cmd_candidates)

    p_filt = sub.add_parser(
        "filter",
        help="Filter a candidates file to T2T contigs passing the "
             "per-chromosome concordance thresholds.")
    p_filt.add_argument("candidates", help="candidates file from the 'candidates' command")
    p_filt.set_defaults(func=cmd_filter)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
