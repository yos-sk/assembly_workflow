#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Reverse complement sequences based on reference table strand information.

This script reads a reference table (output from make_reference_table.py) and
a FASTA file, then outputs sequences with reverse complement applied for
contigs with strand '-' in the reference table.

Usage:
    python3 reverse_complement_ref.py -r <ref_table> -f <fasta> > output.fa
"""

import sys
import argparse
from typing import Dict


def reverse_complement(seq: str) -> str:
    """
    Return reverse complement of DNA sequence.

    Args:
        seq: DNA sequence string

    Returns:
        Reverse complemented sequence
    """
    complement = {'A': 'T', 'T': 'A', 'G': 'C', 'C': 'G',
                  'a': 't', 't': 'a', 'g': 'c', 'c': 'g',
                  'N': 'N', 'n': 'n'}

    # Handle any other characters (e.g., masked sequences)
    rev_comp = ""
    for base in reversed(seq):
        if base in complement:
            rev_comp += complement[base]
        else:
            # Keep non-standard bases as is
            rev_comp += base

    return rev_comp


def load_ref_table(ref_table_file: str) -> Dict[str, tuple]:
    """
    Load reference table and extract contig names and their strand information.

    Args:
        ref_table_file: Path to reference table file

    Returns:
        Dictionary mapping contig names to (strand, chrom, chrom_start, chrom_end)
    """
    ref_info = {}

    with open(ref_table_file, 'r') as f:
        for line in f:
            items = line.rstrip('\n').split('\t')
            if len(items) < 7:
                continue

            # Format: contig, start, end, strand, chrom, chrom_start, chrom_end
            contig = items[0]
            strand = items[3]
            chrom = items[4]
            chrom_start = items[5]
            chrom_end = items[6]

            ref_info[contig] = (strand, chrom, chrom_start, chrom_end)

    return ref_info


def process_fasta(fasta_file: str, ref_info: Dict[str, tuple]) -> None:
    """
    Process FASTA file and output sequences with reverse complement applied
    for contigs with strand '-'.

    Args:
        fasta_file: Path to input FASTA file
        ref_info: Dictionary from load_ref_table()
    """
    current_contig = None
    current_seq = ""

    with open(fasta_file, 'r') as f:
        for line in f:
            line = line.rstrip('\n')

            if line.startswith('>'):
                # Process previous contig if exists
                if current_contig is not None:
                    output_contig(current_contig, current_seq, ref_info)

                # Start new contig
                current_contig = line[1:].split()[0]  # Remove '>' and get first field
                current_seq = ""
            else:
                # Accumulate sequence
                current_seq += line

        # Process last contig
        if current_contig is not None:
            output_contig(current_contig, current_seq, ref_info)


def output_contig(contig: str, seq: str, ref_info: Dict[str, tuple]) -> None:
    """
    Output contig sequence, applying reverse complement if strand is '-'.

    Args:
        contig: Contig name
        seq: Sequence string
        ref_info: Dictionary from load_ref_table()
    """

    if contig not in ref_info:
        output_seq = seq
    else:
        strand, _, _, _ = ref_info[contig]

        # Apply reverse complement if strand is '-'
        if strand == '-':
            output_seq = reverse_complement(seq)
            print(f"# Reverse complementing {contig} (strand: {strand})", file=sys.stderr)
        else:
            output_seq = seq

    # Output in FASTA format
    print(f">{contig}")

    # Split sequence into lines of 60 characters
    line_length = 60
    for i in range(0, len(output_seq), line_length):
        print(output_seq[i:i+line_length])


def create_parser():
    """Create argument parser."""
    parser = argparse.ArgumentParser(
        description='Reverse complement sequences based on reference table strand information',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 reverse_complement_ref.py -r sample.ref.table -f sample.fa > sample.filt.fa

    # With verbose output
    python3 reverse_complement_ref.py -r sample.ref.table -f sample.fa -v > sample.filt.fa

Input format:
    Reference table (TSV):
        contig  start   end strand  chrom   chrom_start chrom_end

    FASTA file:
        Standard FASTA format

Output:
    FASTA file with sequences reverse complemented where strand is '-'
        """
    )

    parser.add_argument('-r', '--ref-table', required=True,
                       help='Reference table file (output from make_reference_table.py)')
    parser.add_argument('-f', '--fasta', required=True,
                       help='Input FASTA file')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Verbose output to stderr')

    return parser


def main():
    parser = create_parser()
    args = parser.parse_args()

    # Load reference table
    if args.verbose:
        print(f"Loading reference table from: {args.ref_table}", file=sys.stderr)

    ref_info = load_ref_table(args.ref_table)

    if args.verbose:
        print(f"Loaded {len(ref_info)} contigs from reference table", file=sys.stderr)
        minus_count = sum(1 for strand, _, _, _ in ref_info.values() if strand == '-')
        plus_count = sum(1 for strand, _, _, _ in ref_info.values() if strand == '+')
        print(f"  Strand '+': {plus_count}", file=sys.stderr)
        print(f"  Strand '-': {minus_count}", file=sys.stderr)
        print("", file=sys.stderr)

    # Process FASTA file
    if args.verbose:
        print(f"Processing FASTA file: {args.fasta}", file=sys.stderr)
        print("", file=sys.stderr)

    process_fasta(args.fasta, ref_info)

    if args.verbose:
        print("", file=sys.stderr)
        print("Processing complete!", file=sys.stderr)


if __name__ == '__main__':
    main()
