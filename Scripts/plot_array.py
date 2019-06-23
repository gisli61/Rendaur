#!/usr/bin/env pythonw

import sys
import matplotlib.pyplot as plt
import matplotlib.widgets as widgets

# Have some code to generate float wav files in
# /Users/gislim/Documents/Musik/Verkefni/makesamples

def main(file):
    if file == '-':
        f = sys.stdin
    else:
        f = open(file)
    c1_array = []
    c2_array = []

    values = [float(x) for x in f.readline().strip().split()]

    arrays = []
    for v in values:
        arrays.append([v])

    for l in f:
        values = [float(x) for x in l.strip().split()]
        i = 0
        for v in values:
            arrays[i].append(v)
            i += 1

    if file != '-':
        f.close()

    for a in arrays:
        plt.plot(a)
    plt.show()

if __name__ == '__main__':
    main(sys.argv[1])