#!/usr/bin/python -u

"""
This program analyzes the output produced by the
OpenSSH client which is patched for analyzing the
key exchange.
"""

from __future__ import print_function

import sys
from os import listdir
from os.path import isfile, isdir, join

DH_BITS_WEAK = 768
DH_BITS_ACADEMIC = 1024
DH_BITS_NATION = 1536
DH_GROUP_BIT_LOG_STRING = "KEX server-chosen group size in bits: "

"""
prints a security ranking for the given Diffie-Hellman group size
in bits
"""
def dh_sec_level(dh_bits):
    print("The Diffie-Hellman group exchange negotiated a group size of",
            dh_bits, "bits.")
    print("The security is ", end="")
    if dh_bits < DH_BITS_WEAK:
        print("WEAK.")
    elif dh_bits < DH_BITS_ACADEMIC:
        print("WEAK-INTERMEDIATE (an academic team might be able to break the security).")
    elif dh_bits < DH_BITS_NATION:
        print("INTERMEDIATE (a nation-state might be able to break the security).")
    else:
        print("STRONG.")

"""
analyze the given file, looking for the chosen Diffie-Hellman group size
"""
def analyze(f):
    file = open(f, "r")

    for line in file.readlines():
        if line.startswith(DH_GROUP_BIT_LOG_STRING):
            ints = [int(s) for s in line.split() if s.isdigit()]
            if len(ints) == 1:
                dh_bits = ints[0]
                dh_sec_level(dh_bits)
            else:
                print("Error: Cannot parse Diffie-Hellman group size!")

"""
analyze all files in the given directory
"""
def walk_dir(d):
    subdirs = sorted(listdir(d))
    for f in subdirs:
        path = join(d, f)
        if isfile(path):
            analyze(path)

"""
parse command-line parameters and start analysis
"""
def main():
    args = sys.argv

    if len(args) != 2:
        print("Syntax: python -u ", args[0], " directory")
        exit(1)
    else:
       directory = args[1]

    if not isdir(directory):
        print("The given parameter is not a directory: ", directory)
        exit(1)

    walk_dir(directory)

if  __name__ =='__main__':
    main()

