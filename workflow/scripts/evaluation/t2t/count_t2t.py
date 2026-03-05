#!/usr/bin/env python3

import sys

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

def t2t_concord(input_paf, candidate_contigs):
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
                    print(prev_contig, max_contig, length, length / ref_length_db[max_contig], sep="\t")
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
            print(prev_contig, max_contig, length, length / ref_length_db[max_contig], sep="\t")

def main():
    input_telo = sys.argv[1]
    input_paf = sys.argv[2]
    
    contigs = extract_contigs(input_telo)
    t2t_concord(input_paf, contigs)

if __name__ == "__main__":
    main()


