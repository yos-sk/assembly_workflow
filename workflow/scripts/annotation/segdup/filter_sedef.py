#!/usr/bin/env python3
"""
Filter sedef (segmental duplication detection) output based on various criteria.

This script processes sedef output and filters duplications based on:
- Alignment length
- Sedef score
- Identity/match fraction
- Gap percentage
- Satellite sequence coverage
"""

import argparse
import sys
from dataclasses import dataclass
from typing import TextIO


@dataclass
class SedefRecord:
    """Represents a single sedef output record with all metrics."""

    # Genomic coordinates
    chrom1: str
    start1: int
    end1: int
    chrom2: str
    start2: int
    end2: int

    # Basic metrics
    name: str
    score: float
    strand1: str
    strand2: str

    # Length metrics
    max_len: int
    aln_len: int

    # Error metrics
    mismatch_error: float
    gapbase_error: float

    # Indel metrics
    indel1: int
    indel2: int

    # Base composition
    align_base: int
    match_base: int
    mismatch_base: int
    transition: int
    transversion: int

    # Identity metrics
    match_fraction: float
    identity: float
    jaccard: float
    kimura: float

    # Gap metrics
    aln_gaps: int
    aln_gap_bases: int

    # Uppercase metrics
    uppercase1: int
    uppercase2: int
    uppercase_matches: int

    # Alignment details
    aln_matches: int
    aln_mismatches: int
    cigar: str

    # Derived metrics
    gap_compressed_identity: float
    count_ovls: int

    # Satellite annotation
    sat_bases: int
    total_bases: int
    sat_coverage: float

    @classmethod
    def from_line(cls, line: str) -> 'SedefRecord':
        """
        Parse a sedef output line into a SedefRecord.

        Args:
            line: Tab-delimited sedef output line

        Returns:
            SedefRecord object

        Raises:
            ValueError: If line cannot be parsed
        """
        items = line.rstrip('\n').split('\t')

        if len(items) < 38:
            raise ValueError(f"Expected at least 38 fields, got {len(items)}")

        # Parse error fields (format: "M=X;G=Y")
        error_parts = items[12].split(';')
        mismatch_error = float(error_parts[0].split('=')[1])
        gapbase_error = float(error_parts[1].split('=')[1])

        return cls(
            chrom1=items[0],
            start1=int(items[1]),
            end1=int(items[2]),
            chrom2=items[3],
            start2=int(items[4]),
            end2=int(items[5]),
            name=items[6],
            score=float(items[7]),
            strand1=items[8],
            strand2=items[9],
            max_len=int(items[10]),
            aln_len=int(items[11]),
            mismatch_error=mismatch_error,
            gapbase_error=gapbase_error,
            indel1=int(items[13]),
            indel2=int(items[14]),
            align_base=int(items[15]),
            match_base=int(items[16]),
            mismatch_base=int(items[17]),
            transition=int(items[18]),
            transversion=int(items[19]),
            match_fraction=float(items[20]),
            identity=float(items[21]),
            jaccard=float(items[22]),
            kimura=float(items[23]),
            aln_gaps=int(items[24]),
            uppercase1=int(items[25]),
            uppercase2=int(items[26]),
            uppercase_matches=int(items[27]),
            aln_matches=int(items[28]),
            aln_mismatches=int(items[29]),
            # items[30] is num_gaps - skipped
            aln_gap_bases=int(items[31]),
            cigar=items[32],
            gap_compressed_identity=float(items[33]),
            count_ovls=int(items[34]),
            sat_bases=int(items[35]),
            total_bases=int(items[36]),
            sat_coverage=float(items[37])
        )

    def passes_filters(
        self,
        min_alignment_length: int,
        max_sedef_score: int,
        min_identity: int,
        min_percent_gaps: int,
        min_percent_satellite: int
    ) -> bool:
        """
        Check if this record passes all filter criteria.

        Args:
            min_alignment_length: Minimum alignment length (bp)
            max_sedef_score: Maximum sedef score threshold
            min_identity: Minimum match fraction (%)
            min_percent_gaps: Minimum gap percentage threshold (%)
            min_percent_satellite: Minimum satellite coverage threshold (%)

        Returns:
            True if record passes all filters, False otherwise
        """
        # Filter by alignment length
        if self.aln_len <= min_alignment_length:
            return False

        # Filter by sedef score (lower is better)
        if self.score >= max_sedef_score:
            return False

        # Filter by identity (match fraction as percentage)
        if self.match_fraction * 100 <= min_identity:
            return False

        # Filter by gap percentage
        gap_percentage = (self.aln_gap_bases / self.aln_len * 100) if self.aln_len > 0 else 0
        if gap_percentage >= min_percent_gaps:
            return False

        # Filter by satellite coverage
        if self.sat_coverage * 100 >= min_percent_satellite:
            return False

        return True


def filter_sedef_output(
    input_file: TextIO,
    min_alignment_length: int = 1000,
    max_sedef_score: int = 50,
    min_identity: int = 90,
    min_percent_gaps: int = 50,
    min_percent_satellite: int = 70
) -> None:
    """
    Filter sedef output records and print those passing criteria.

    Args:
        input_file: Input file handle containing sedef output
        min_alignment_length: Minimum alignment length in bp (default: 1000)
        max_sedef_score: Maximum sedef score (default: 50)
        min_identity: Minimum identity percentage (default: 90)
        min_percent_gaps: Maximum gap percentage (default: 50)
        min_percent_satellite: Maximum satellite percentage (default: 70)
    """
    for line in input_file:
        # Skip comment lines
        if line.startswith('#'):
            continue

        try:
            record = SedefRecord.from_line(line)
        except (ValueError, IndexError) as e:
            print(f"Warning: Failed to parse line: {e}", file=sys.stderr)
            continue

        # Apply filters
        if record.passes_filters(
            min_alignment_length=min_alignment_length,
            max_sedef_score=max_sedef_score,
            min_identity=min_identity,
            min_percent_gaps=min_percent_gaps,
            min_percent_satellite=min_percent_satellite
        ):
            print(line.rstrip('\n'))


def main() -> None:
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        prog="filter_sedef",
        description="Filter sedef results based on quality metrics"
    )

    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="Path to sedef original result (BEDPE format)"
    )

    parser.add_argument(
        "--min_alignment_length",
        type=int,
        default=1000,
        help="Minimum alignment length in bp (default: 1000)"
    )

    parser.add_argument(
        "--min_identity",
        type=int,
        default=90,
        help="Minimum match fraction as percentage (default: 90)"
    )

    parser.add_argument(
        "--min_percent_gaps", "-g",
        type=int,
        default=50,
        help="Maximum percentage of gaps in alignment (default: 50)"
    )

    parser.add_argument(
        "--min_percent_satellite",
        type=int,
        default=70,
        help="Maximum percentage of satellite sequences (default: 70)"
    )

    parser.add_argument(
        "--max_sedef_score",
        type=int,
        default=50,
        help="Maximum sedef score threshold (default: 50)"
    )

    args = parser.parse_args()

    with open(args.input, 'r') as f:
        filter_sedef_output(
            input_file=f,
            min_alignment_length=args.min_alignment_length,
            max_sedef_score=args.max_sedef_score,
            min_identity=args.min_identity,
            min_percent_gaps=args.min_percent_gaps,
            min_percent_satellite=args.min_percent_satellite
        )


if __name__ == "__main__":
    main()
