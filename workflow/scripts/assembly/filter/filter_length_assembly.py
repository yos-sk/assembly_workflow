#!/bin/bash

import sys

def filter(input_file, output_file, length=100000):
    contig = ""
    seq = ""
    with open(input_file, "r") as f, open(output_file, "w") as w:
        for line in f:
            if line[0] == ">":
                if contig != "" and seq != "":
                    if len(seq) >= length:
                        print(contig, file=w)
                        print(seq, file=w)
                contig = line.rstrip("\n")
                seq = ""
            else:
                seq += line.rstrip("\n")

        if contig != "" and seq != "":
            if len(seq) >= length:
                print(contig, file=w)
                print(seq, file=w)

def main():
    hap1 = sys.argv[1]
    hap2 = sys.argv[2]
    output_hap1 = sys.argv[3]
    output_hap2 = sys.argv[4]

    filter(hap1, output_hap1)
    filter(hap2, output_hap2)

if __name__ == "__main__":
    main()
