#! /usr/bin/env python

import sys

rmsk_file = sys.argv[1]

with open(rmsk_file, 'r') as f:
    for i, line in enumerate(f):
        if i < 3: continue
        F = line.strip().split()
        # if len(F[5]) > 5: continue
        if int(F[6]) - int(F[5]) + 1 < 5800: continue
        if F[10] != "LINE/L1": continue
        if not F[9] in ["L1HS", "L1PA2", "L1PA3", "L1PA4", "L1PA5"]: continue
        strand = "-" if F[8] == "C" else "+"
        label = ','.join([F[4], str(int(F[5]) - 1), F[6], strand, F[9]])
        print('\t'.join([F[4], str(int(F[5]) - 1), F[6], label, '0', strand]))
 
