#!/usr/bin/env python3
"""Convert an Android sparse image (what GSIs ship as) to a raw ext4 image.
Usage: python3 -I unsparse.py <in-sparse.img> <out-raw.img>
(simg2img from android-tools does the same if you have it.)"""
import struct, sys
src, dst = sys.argv[1:3]
f = open(src, "rb")
magic, maj, mino, fhs, chs, bs, tb, tc, crc = struct.unpack("<IHHHHIIII", f.read(28))
if magic != 0xED26FF3A:
    sys.exit("not a sparse image (already raw?)")
out = open(dst, "wb")
for _ in range(tc):
    ch = f.read(chs)
    t, _, sz, tsz = struct.unpack("<HHII", ch[:12])
    if t == 0xCAC1:   out.write(f.read(tsz - chs))             # RAW
    elif t == 0xCAC2: out.write(f.read(4) * (sz * bs // 4))    # FILL
    elif t == 0xCAC3: out.seek(sz * bs, 1)                     # DONT_CARE
    elif t == 0xCAC4: f.read(4)                                # CRC32
out.truncate(tb * bs)
out.close()
print("wrote", dst, tb * bs, "bytes")
