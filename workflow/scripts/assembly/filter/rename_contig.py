#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rename assembly contigs to PanSN-style names using a reference table.

Reads a reference table (output from make_reference_table.py) and a FASTA file,
then rewrites each FASTA header as: {sample}#{haplotype}#{chrom}

When several contigs are assigned to the same reference chromosome, they are
ordered by reference start position and suffixed: {chrom}_ctg1, {chrom}_ctg2, ...
Contigs not confidently assigned to any chromosome (absent from the reference
table) are renamed {sample}#{haplotype}#unassigned_ctgN in FASTA order.

This script only renames headers; sequence content and orientation are passed
through unchanged (reverse-complementing is handled upstream with seqtk).

Usage:
    python3 rename_contig.py -r <ref_table> -f <fasta> \
        --sample <sample> --haplotype <1|2> > renamed.fa
"""

import sys
import argparse
from typing import Dict, List, Tuple


def load_ref_table(ref_table_file: str) -> Dict[str, Tuple[str, int]]:
    """Load reference table.

    Returns a dict mapping assembly contig -> (chrom, chrom_start), where chrom
    is the assigned reference chromosome.
    Format: contig, start, end, strand, chrom, chrom_start, chrom_end
    """
    ref_info = {}
    with open(ref_table_file, 'r') as f:
        for line in f:
            items = line.rstrip('\n').split('\t')
            if len(items) < 7:
                continue
            contig = items[0]
            chrom = items[4]
            try:
                chrom_start = int(items[5])
            except ValueError:
                chrom_start = 0
            ref_info[contig] = (chrom, chrom_start)
    return ref_info


def build_name_map(ref_info: Dict[str, Tuple[str, int]],
                   sample: str, haplotype: str) -> Dict[str, str]:
    """Build assembly-contig -> PanSN name for chromosome-assigned contigs.

    Single contig per chromosome    -> {sample}#{hap}#{chrom}
    Multiple contigs per chromosome  -> {sample}#{hap}#{chrom}_ctgN
        (N ordered by reference start position; ties broken by contig name)
    """
    by_chrom: Dict[str, List[Tuple[int, str]]] = {}
    for contig, (chrom, chrom_start) in ref_info.items():
        by_chrom.setdefault(chrom, []).append((chrom_start, contig))

    name_map = {}
    for chrom, entries in by_chrom.items():
        entries.sort()  # by (chrom_start, contig)
        if len(entries) == 1:
            name_map[entries[0][1]] = f"{sample}#{haplotype}#{chrom}"
        else:
            for i, (_start, contig) in enumerate(entries, start=1):
                name_map[contig] = f"{sample}#{haplotype}#{chrom}_ctg{i}"
    return name_map


def rename_fasta(fasta_file: str, name_map: Dict[str, str],
                 sample: str, haplotype: str) -> None:
    """Stream the FASTA, rewriting headers; sequence lines pass through verbatim."""
    unassigned = 0
    with open(fasta_file, 'r') as f:
        for line in f:
            if line.startswith('>'):
                contig = line[1:].rstrip('\n').split()[0]
                if contig in name_map:
                    new_name = name_map[contig]
                else:
                    unassigned += 1
                    new_name = f"{sample}#{haplotype}#unassigned_ctg{unassigned}"
                print(f">{new_name}")
            else:
                sys.stdout.write(line)


def create_parser():
    parser = argparse.ArgumentParser(
        description='Rename assembly contigs to PanSN names using a reference table')
    parser.add_argument('-r', '--ref-table', required=True,
                        help='Reference table file (output from make_reference_table.py)')
    parser.add_argument('-f', '--fasta', required=True,
                        help='Input FASTA file')
    parser.add_argument('-s', '--sample', required=True,
                        help='Sample name (PanSN field 1)')
    parser.add_argument('-p', '--haplotype', required=True,
                        help='Haplotype (PanSN field 2), e.g. 1 or 2')
    return parser


def main():
    args = create_parser().parse_args()
    ref_info = load_ref_table(args.ref_table)
    name_map = build_name_map(ref_info, args.sample, args.haplotype)
    rename_fasta(args.fasta, name_map, args.sample, args.haplotype)


if __name__ == '__main__':
    main()
