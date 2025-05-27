#!/usr/bin/env python3

"""
This program analyzes the output produced by the OpenSSH client which is
patched for analyzing the key exchange.

SSH-Weak-DH v4.1
Fabian Foerg <ffoerg@gdssecurity.com>
Ron Gutierrez <rgutierrez@gdssecurity.com>
Blog: https://www.aon.com/cyber-solutions/aon_cyber_labs/ssh-weak-diffie-hellman-group-identification-tool/
Copyright 2015-2025 Gotham Digital Science
"""

from Crypto.Util.number import bytes_to_long, isPrime
from os import listdir
from os.path import isfile, isdir, join
import json
import math
import re
import sys

# Parameters for Diffie-Hellman groups
DH_BITS_WEAK = 768
DH_BITS_ACADEMIC = 1024
DH_BITS_NATION = 1536

# Keys in scan output
KEX_ALGO = "KEX algorithm chosen: "
DH_GROUP_BIT_CLIENT = "KEX client group sizes: "
DH_GROUP_BIT_SERVER = "KEX server-chosen group size in bits: "
DH_GROUP1 = "diffie-hellman-group1-sha1"
PRIME_IDENTIFIER = " prime in hex: "
GENERATOR_IDENTIFIER = " generator in hex: "


# Load common groups with metadata from file:
def _parse_common_groups_file(filename):
    """
    returns a dictionary populated with common prime numbers as keys and
    metadata as values
    """
    if not isfile(filename):
        print("Expected common groups file under", filename)
        exit(1)

    objects = {}
    with open(filename, "r") as file:
        objects = json.load(file)

    result = {}

    for common_group in objects["data"]:
        group_meta = {
            "generator": common_group["g"],
            "is_prime": common_group["prime"],
            "is_safe_prime": common_group["safe_prime"],
            "name": common_group["name"],
            "num_bits": common_group["length"],
        }
        result[common_group["p"]] = group_meta

    return result


COMMON_GROUPS = _parse_common_groups_file("common.json")


def _check_group(n_hex):
    """
    checks whether the given hexadecimal string represents a safe prime and
    whether it is a common group
    """
    p = bytes_to_long(bytes.fromhex(n_hex))

    # Check if p is a safe prime
    q = (p - 1) // 2

    if not isPrime(q) or not isPrime(p):
        print("[!] BROKEN. {} is not a safe prime.".format(n_hex))
    else:
        num_bits = math.ceil(len(n_hex) / 2) * 8
        sec_level_str, sec_level_symbol = _get_sec_level_tuple(num_bits)
        name = COMMON_GROUPS[p]["name"] if p in COMMON_GROUPS else None
        name_message = " named {}".format(name) if name else ""

        print(
            "[{}] {}. {} is a safe {}-bit prime{}.".format(
                sec_level_symbol, sec_level_str, n_hex, num_bits, name_message
            )
        )


def _check_generator(g_hex, p_hex):
    """
    checks whether 1 < g < p - 1 where g and p are the integers represented by
    the given first and second hexadecimal string arguments, respectively
    """
    g = bytes_to_long(bytes.fromhex(g_hex))
    p = bytes_to_long(bytes.fromhex(p_hex))

    if g <= 1 or g >= (p - 1):
        print("[!] BROKEN. {} must not be used as a generator.".format(g_hex))


def _get_sec_level_tuple(dh_bits):
    """
    returns a security ranking for the given number of bits as a tuple
    consisting of a descriptive string and a representative symbol
    """
    sec_level_str, sec_level_symbol = "", ""
    if dh_bits < DH_BITS_WEAK:
        sec_level_str, sec_level_symbol = "WEAK", "!"
    elif dh_bits < DH_BITS_ACADEMIC:
        sec_level_str, sec_level_symbol = (
            "WEAK-INTERMEDIATE (might be feasible to break for academic teams)",
            "-",
        )
    elif dh_bits < DH_BITS_NATION:
        sec_level_str, sec_level_symbol = (
            "INTERMEDIATE (might be feasible to break for nation-states)",
            "*",
        )
    else:
        sec_level_str, sec_level_symbol = "STRONG", "+"
    return sec_level_str, sec_level_symbol


def _dh_sec_level(dh_algo, dh_bits_client, dh_bits_server):
    """
    prints a security ranking for the given Diffie-Hellman group size in bits
    """
    assert len(dh_bits_client) == 3
    sec_level_str, sec_level_symbol = _get_sec_level_tuple(dh_bits_server)

    info = (
        "[{}] {}. Algorithm: {}. Negotiated group size in bits: {}. "
        "Group size proposed by client in bits: min={}, nbits={}, max={}.".format(
            sec_level_symbol,
            sec_level_str,
            dh_algo,
            dh_bits_server,
            dh_bits_client[0],
            dh_bits_client[1],
            dh_bits_client[2],
        )
    )
    print(info)


def _parse_group_exchange(lines, dh_algo):
    """
    parses the two given lines for Diffie-Hellman group exchange parameters
    """
    assert len(lines) == 2

    fst = lines[0]
    snd = lines[1]

    if fst.startswith(DH_GROUP_BIT_CLIENT) and snd.startswith(DH_GROUP_BIT_SERVER):
        dh_bits_client = [int(s) for s in re.split(r"\s+|\s*,\s*", fst) if s.isdigit()]
        dh_bits_server = [int(s) for s in snd.split() if s.isdigit()]

        if len(dh_bits_client) == 3 and len(dh_bits_server) == 1:
            _dh_sec_level(dh_algo, dh_bits_client, dh_bits_server[0])
        else:
            print("Error: Cannot parse client parameters or server group size!")


def _analyze(f):
    """
    analyze the given file, looking for Diffie-Hellman group sizes and
    algorithm
    """
    lines = []
    with open(f, "r") as fb:
        lines = [line.rstrip("\n") for line in fb]
    lineno = 0
    dh_algo = ""
    dh_bits_client = (0, 0, 0)
    dh_bits_server = 0
    p_hex = None

    while lineno < len(lines):
        line = lines[lineno]
        if PRIME_IDENTIFIER in line:
            p_hex = line.split(PRIME_IDENTIFIER)[1]
            _check_group(p_hex)
        elif GENERATOR_IDENTIFIER in line:
            assert p_hex
            g_hex = line.split(GENERATOR_IDENTIFIER)[1]
            _check_generator(g_hex, p_hex)
            p_hex = None
        elif line.startswith(KEX_ALGO):
            dh_algo = line[len(KEX_ALGO) :].strip()
            # Treat DH group1 (Oakley Group 2) individually, since it is
            # negotiated via the diffie-hellman-group1-sha1 method and not the
            # DH GEX methods (the client does not propose group sizes, since
            # the group is fixed).
            if dh_algo == DH_GROUP1:
                _dh_sec_level(dh_algo, [1024, 1024, 1024], 1024)
        elif (lineno + 2) <= len(lines):
            _parse_group_exchange(lines[lineno : lineno + 2], dh_algo)
        lineno += 1


def _walk_dir(d):
    """
    analyze all files in the given directory
    """
    subdirs = sorted(listdir(d))
    for f in subdirs:
        path = join(d, f)
        if isfile(path):
            _analyze(path)


def main():
    """
    parse command-line parameters and start analysis
    """
    args = sys.argv

    if len(args) != 2:
        print("Syntax:", args[0], "directory")
        exit(1)

    directory = args[1]

    if not isdir(directory):
        print("The given parameter is not a directory: ", directory)
        exit(1)

    _walk_dir(directory)

    print("")
    print(
        "WARNING: This tool tests a limited set of configurations and might miss some weaknesses. Additionally, the server might block connections before the scan finishes."
    )


if __name__ == "__main__":
    main()
