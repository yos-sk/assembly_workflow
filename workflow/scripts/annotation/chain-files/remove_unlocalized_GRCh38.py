#!/usr/bin/env python3

import sys

def main():
    hg38 = sys.argv[1]
    flag = False
    with open(hg38, "r") as f:
        for line in f:
            if line[0] == ">":
                stat = ""
                for tag in line.rstrip("\n").split():
                    if tag[:3] == "rl:":
                        stat = line.rstrip("\n").split()[4][3:]
                        break

                if stat != "Chromosome":
                    flag = False
                else:
                    flag = True
                    print(line.rstrip("\n"))
            else:
                if flag:
                    print(line.rstrip("\n"))

if __name__ == "__main__":
    main()
