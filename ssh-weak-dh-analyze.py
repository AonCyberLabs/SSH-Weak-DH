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
import re

DH_BITS_WEAK = 768
DH_BITS_ACADEMIC = 1024
DH_BITS_NATION = 1536
KEX_ALGO = "KEX algorithm chosen: "
DH_GROUP_BIT_CLIENT = "KEX client group sizes: "
DH_GROUP_BIT_SERVER = "KEX server-chosen group size in bits: "

"""
prints a security ranking for the given Diffie-Hellman group size
in bits
"""
def dh_sec_level(dh_algo, dh_bits_client, dh_bits_server):
    print("The client proposed the following group size parameters (in bits): min=", dh_bits_client[0], ", nbits=", dh_bits_client[1], ", max=", dh_bits_client[2], ".", sep='')
    print("The client and server negotiated a group size of ",
            dh_bits_server, " using ", dh_algo, ".", sep='')
    print("The security level is ", end="")
    if dh_bits_server < DH_BITS_WEAK:
        print("WEAK.")
    elif dh_bits_server < DH_BITS_ACADEMIC:
        print("WEAK-INTERMEDIATE (might be feasible to break for academic teams).")
    elif dh_bits_server < DH_BITS_NATION:
        print("INTERMEDIATE (might be feasible to break for nation-states).")
    else:
        print("STRONG.")
    print()

"""
analyze the given file, looking for Diffie-Hellman group sizes and
algorithm
"""
def analyze(f):
    file = open(f, "r")
    lines = file.readlines()
    lineno = 0
    dh_algo = ""
    dh_bits_client = (0, 0, 0)
    dh_bits_server = 0

    while (lineno + 2) < len(lines):
        line = lines[lineno]
        if line.startswith(KEX_ALGO):
            dh_algo = line[len(KEX_ALGO):].strip()
        line = lines[lineno + 1]
        if line.startswith(DH_GROUP_BIT_CLIENT):
            ints = [int(s) for s in re.split('\s+|\s*,\s*', line) if s.isdigit()]
            if len(ints) == 3:
                dh_bits_client = ints
            else:
                print("Error: Cannot parse client parameters!")
                break
        line = lines[lineno + 2]
        if line.startswith(DH_GROUP_BIT_SERVER):
            ints = [int(s) for s in line.split() if s.isdigit()]
            if len(ints) == 1:
                dh_bits_server = ints[0]
                dh_sec_level(dh_algo, dh_bits_client, dh_bits_server)
            else:
                print("Error: Cannot parse server group size!")
                break
        lineno += 1

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
        print("Syntax: python -u", args[0], "directory")
        exit(1)
    else:
       directory = args[1]

    if not isdir(directory):
        print("The given parameter is not a directory: ", directory)
        exit(1)

    walk_dir(directory)

if  __name__ =='__main__':
    main()

