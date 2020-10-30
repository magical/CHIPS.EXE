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

def main():
    for mod in modules:
        symbols.setdefault(mod, {})
        try:
            with open("reloc.orig/{}.sym".format(mod)) as f:
                for line in f:
                    if line.count(" ") == 1:
                        ordinal, name = line.split()
                        ordinal = int(ordinal)
                        symbols[mod][ordinal] = name
                    elif " equate " in line:
                        ordinal, _, name, _ = line.split(maxsplit=3)
                        symbols[mod][int(ordinal)] = name
        except IOError as e:
            print(e, file=sys.stderr)

    with open(sys.argv[1], "rb") as f:
        if len(sys.argv) == 3:
            segment = int(sys.argv[2], 0)
            for seg, base, offset in segments:
                if seg == segment:
                    dumpreloc(f, base, offset)
                    break
            else:
                print("no such segment", file=sys.stderr)
        elif len(sys.argv) == 4:
            base = int(sys.argv[2], 0)
            offset = int(sys.argv[3], 0)
            dumpreloc(f, base, offset)
        else:
            for seg, base, offset in segments:
                print(";;; SEGMENT %d ;;;" % seg)
                dumpreloc(f, base, offset)
                print()

def dumpreloc(f, base, offset):
    #print(hex(base), hex(offset), hex(base+offset))
    f.seek(base+offset)
    nreloc = read16(f)
    relocdata = f.read(8*nreloc)
    patchlist = []
    #print("    dw", nreloc, "; number of relocations")

    for j in range(nreloc):
        r = relocdata[j*8 : j*8+8]
        #print(fmt_reloc(r))

        # Follow source chain
        addr, = struct.unpack("<H", r[2:4])
        p = []
        while addr != 0xffff:
            p.append(addr)
            #print(hex(addr))

            f.seek(base+addr)
            value = read16(f)
            if value == addr:
                raise RuntimeError("cycle detected")
            addr = value

        p.reverse()

        for i, x in enumerate(p):
            patchlist.append((j, i, x))

        if len(p) > 1:
            #print(j, ":", p)
            #print(j, ":", find_runs(p))
            #print(j, ":", find_and_format_runs(p))
            #print(j, ":", *["%x"%x for x in p])
            #print("#", *["%x"%x for x in p])
            s = str(j) + " " + fmt_reloc(r) + " :"
            print(s.ljust(40), find_and_format_runs(p))
            runs = find_runs(p)
            for k, m in zip(range(len(runs)), range(1, len(runs))):
                if not max(runs[k]) < min(runs[m]):
                    print("error: %x > %x" % (max(runs[k]),  min(runs[m])))

    patchlist.sort(key=lambda x: (x[2]))
    #print(patchlist)
    

def find_runs(p):
    runs = []
    i = 0
    while i < len(p):
        end = i
        if i+1 < len(p) and p[i] < p[i+1]:
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
            for j in range(i+1, len(p)):
                if p[j-1] > p[j]:
                    end = j
                else:
                    break
        runs.append((p[i], p[end]))
        i = end+1
    return runs

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
