#!/usr/bin/env python3
# finds runs of increasing or decreasing addresses in the relocation chains

import os
import struct
import sys

modules = ["KERNEL", "GDI", "USER", "WEP4UTIL"]
symbols = {}

segments = [
    (1, 0xa00, 0x952),
    (2, 0x1600, 0x2dca),
    (10, 0x4800, 0x1738),
    (3, 0x6200, 0x2a70),
    (4, 0x8e00, 0x1208),
    (5, 0xa200, 0x1bc),
    (6, 0xa600, 0x75b),
    (7, 0xae00, 0x1cd4),
    (8, 0xcc00, 0x620),
    (9, 0xd400, 0x150),
]

verbose = False #or True

def main():
    for mod in modules:
        symbols.setdefault(mod, {})
        try:
            with open("tools/reloc.orig/{}.sym".format(mod)) as f:
                for line in f:
                    if line.count(" ") == 1:
                        ordinal, name = line.split()
                        ordinal = int(ordinal)
                        symbols[mod][ordinal] = name
                    elif line.count(" ") >= 2:
                        try:
                            ordinal, _, name, *_ = line.split(maxsplit=3)
                            symbols[mod][int(ordinal)] = name
                        except ValueError as e:
                            raise ValueError(line)
        except IOError as e:
            print(e, file=sys.stderr)

    with open(sys.argv[1], "rb") as f:
        if len(sys.argv) == 3:
            segment = int(sys.argv[2], 0)
            for seg, base, offset in segments:
                if seg == segment:
                    dumpreloc(f, seg, base, offset)
                    break
            else:
                print("no such segment", file=sys.stderr)
        elif len(sys.argv) == 4:
            base = int(sys.argv[2], 0)
            offset = int(sys.argv[3], 0)
            dumpreloc(f, 0, base, offset)
        else:
            for i, mod in enumerate(modules):
                print("MODULE %d %s %s.sym" % (i+1, mod, mod))
            print()
            for seg, base, offset in segments:
                print(";;; SEGMENT %d ;;;" % seg)
                dumpreloc(f, seg, base, offset)
                print()

def dumpreloc(f, seg, base, offset):
    #print(hex(base), hex(offset), hex(base+offset))
    f.seek(base+offset)
    nreloc = read16(f)
    relocdata = f.read(8*nreloc)
    #print("    dw", nreloc, "; number of relocations")

    for j in range(nreloc):
        r = relocdata[j*8 : j*8+8]
        #print(fmt_reloc(r))

        # Follow source chain
        addr, = struct.unpack("<H", r[2:4])
        p = [] # patch list
        while addr != 0xffff:
            p.append(addr)
            #print(hex(addr))

            f.seek(base+addr)
            value = read16(f)
            if value == addr:
                raise RuntimeError("cycle detected")
            addr = value
        p.reverse()

        s = "RELOC %s %s" % (seg, get_reloc_sym(r))
        if verbose:
            #s = str(j) + " " + fmt_reloc(r) + " :"
            print(s.ljust(40), *["%x"%x for x in p])
        else:
            if len(p) == 1:
                print(s)
            else:
                runs = find_runs(p)
                #print(" "*len(s.ljust(40)), ";", *["%x"%x for x in p])
                #print(" "*len(s.ljust(40)), ";", find_and_format_runs(p))
                print(s.ljust(40), "=", fmt_simplified_runs(runs))

        runs = find_runs(p)
        for k, m in zip(range(len(runs)), range(1, len(runs))):
            if not max(runs[k]) < min(runs[m]):
                print("error: %x > %x" % (max(runs[k]),  min(runs[m])))

        check_patchlist(p, fmt_simplified_runs(runs))



def find_runs(p):
    """finds runs of increasing or decreasing numbers in p (a list of int).
    returns a list of tuples (a,b) where a>b represents a decreasing run from a to b and a<b is an increasing run.
    may include 0-width runs (a=b)"""
    runs = []
    i = 0
    while i < len(p):
        end = i
        if i+1 < len(p) and p[i] < p[i+1]:
            # ascending
            for j in range(i+1, len(p)):
                if p[j-1] < p[j]:
                    if j == len(p)-1:
                        end = j
                    else:
                        end = j-1
                else:
                    break
            if end - i == 1:
                end = i
        elif i+1 < len(p) and p[i] > p[i+1]:
            # descending
            for j in range(i+1, len(p)):
                if p[j-1] > p[j]:
                    end = j
                else:
                    break
        runs.append((p[i], p[end]))
        i = end+1
    return runs

def fmt_simplified_runs(runs):
    # turn a sequence of spans into a sequence of points
    # by creating cut points halfway between the spaces between spans.
    # p keeps track of the last cut point

    # given
    #  | 3-6 | c-a | x-z
    # we should get (roughly)
    #  0+    8-    m+
    p = 0
    lo = -1
    s = []
    for start, end in runs:
        if lo >= 0:
            hi = min(start,end) # start of this span, end of empty space
            mid = lo + (hi-lo)//2
            p = mid

        if start < end:
            s.append("%x+" % p)
        elif start > end:
            s.append("%x-" % p)
        else: # start == end:
            # TODO maybe do something special?
            s.append("%x-"%p) # direction doesn't matter

        lo = max(start,end)+2 # end of this span, start of empty space

    return " ".join(s)


def find_and_format_runs(p):
    s = []
    for start, end in find_runs(p):
        if start == end:
            s.append("%x"%start)
        elif start < end:
            s.append("%x..%x+"%(start, end))
        else: # start > end:
            s.append("%x..%x-"%(end, start))

    return " ".join(s)

def check_patchlist(addresses, patchlist_str):
    """checks that the list of addreses is in the correct order according to the patchlist specification"""
    # sort the list of addresses,
    # apply the ordering given in the patchlist spec
    # and compare the two lists
    # they should be identical

    # iterate through the cuts
    p = sorted(addresses)
    cuts = patchlist_str.split()
    start = 0
    for cut, nextcut in zip(cuts, cuts[1:]+[None]):
        cutaddr = int(cut.rstrip('-+'), 16)
        while start < len(p) and p[start] < cutaddr:
            start += 1

        if nextcut is None:
            end = len(p)
        else:
            nextaddr = int(nextcut.rstrip('-+'), 16)
            end = start
            while end < len(p) and p[end] < nextaddr:
                end += 1

        # if it ends with + we don't have to do anything
        if cut.endswith('-'):
            p[start:end] = reversed(p[start:end])

        start = end

    if p != addresses:
        print("; warning: patchlist doesn't match spec")
        #print("want:", addresses)
        #print("got: ", p)
        #assert p == addresses

def get_reloc_sym(r):
    addr, = struct.unpack("<H", r[2:4])
    if r[1] == 0:
        seg = r[4]
        num = r[6] + (r[7]<<8)
        if seg != 0xff and num == 0:
            # segment internal
            return "SEGMENT {}".format(seg)
        else:
            return "<unknown>"
    elif r[1] == 1:
        mod, num = struct.unpack("<HH", r[4:8])
        modname = modules[mod-1]
        entry = symbols[modname].get(num, "@"+str(num))
        return "{:7s} {}".format(modname, entry)
    else:
        return "<unknown>"

def fmt_reloc(r):
    addr, = struct.unpack("<H", r[2:4])
    if r[0] == 2 and r[1] == 0:
        seg = r[4]
        num = r[6] + (r[7]<<8)
        if seg != 0xff and num == 0:
            return "SEGMENT INTERNAL {}".format(seg)
        else:
            return fmt_unknown(r)
    elif r[0] == 3 and r[1] == 1:
        mod, num = struct.unpack("<HH", r[4:8])
        modname = modules[mod-1]
        entry = symbols[modname].get(num, str(num))
        return "IMPORT ORDINAL {}.{}".format(modname, entry)
        return "    {:40} ; {}".format(insn, comment)
    elif r[0] == 5 and r[1] == 1:
        mod, num = struct.unpack("<HH", r[4:8])
        modname = modules[mod-1]
        entry = symbols[modname].get(num, str(num))
        return "OFFSET IMPORT {}.{}".format(modname, entry)
    else:
        return fmt_unknown(r)

def fmt_unknown(r):
    a, b, c, d = struct.unpack("<HHHH", r)
    return "UNKNOWN {:#x} {:#x} {:#x} {:#x}".format(a, b, c, d)

def read16(f):
    b = f.read(2)
    if not b:
        raise IOError("couldn't read from %r at %#x" % (f.name, f.tell()))
    n, = struct.unpack("<H", b)
    return n

if __name__ == '__main__':
    main()
