#!/usr/bin/env python3
"""Extract Interstate '76 ZFS archives (I76.ZFS, "ZFSF" v1).

Format (reverse-engineered by the Open76 project and That Tony's blog):
  header: magic "ZFSF" | u32 version(=1) | u32 unk | u32 filesPerDir | u32 numFiles | u32 unk2 | u32 unk3
  then directory blocks: each block holds `filesPerDir` 24-byte entries followed by
  a u32 pointer to the next block. Entry:
    char[16] name (NUL-terminated) | u32 offset | u32 id | u32 length | u32 unk | u8 compression | u24 decompressedLength
  compression: 0 = stored, 2 = LZO1X, 4 = LZO1Y

Usage:
  zfs_extract.py I76.ZFS out_dir            # extract everything
  zfs_extract.py I76.ZFS out_dir 'dash'     # only names containing a substring
  zfs_extract.py I76.ZFS --list             # just list names/sizes/compression
"""
import struct, sys, os

def parse_toc(data):
    magic, version, _unk1, per_dir, total, _u2, _u3 = struct.unpack_from("<4s6I", data, 0)
    assert magic == b"ZFSF" and version == 1, f"not a ZFSF v1 archive ({magic} v{version})"
    entries, pos = [], 0x1C
    while len(entries) < total:
        n = min(per_dir, total - len(entries))
        for i in range(n):
            off = pos + i * 24
            name = data[off:off + 16].split(b"\0")[0].decode("ascii", "replace").lower()
            offset, fid, length, _unk = struct.unpack_from("<4I", data, off + 16)
            entries.append((name, offset, length))
        # after a full block of per_dir entries comes a u32 next-block pointer
        pos = struct.unpack_from("<I", data, pos + per_dir * 24)[0] if n == per_dir else pos
    return entries

def entry_body(data, offset, length):
    """Entry payload starts with its own small header at `offset`:
    char[16] name | u32 id | u32 length | u8 compression | u24 decompressedLen, then data."""
    name = data[offset:offset + 16].split(b"\0")[0].decode("ascii", "replace")
    fid, ln = struct.unpack_from("<2I", data, offset + 16)
    comp = data[offset + 24]
    dlen = int.from_bytes(data[offset + 25:offset + 28], "little")
    payload = data[offset + 28:offset + 28 + ln]
    return name, comp, dlen, payload

def lzo1x_decompress(src, dlen):
    try:
        import lzo
        return lzo.decompress(src, False, dlen)
    except ImportError:
        sys.exit("compressed entry: pip install python-lzo")

def main():
    args = [a for a in sys.argv[1:] if a != "--list"]
    do_list = "--list" in sys.argv
    zfs = args[0]
    data = open(zfs, "rb").read()
    entries = parse_toc(data)
    if do_list:
        for name, offset, length in entries:
            _, comp, dlen, _p = entry_body(data, offset, length)
            print(f"{name:16s} {length:9d} comp={comp} -> {dlen}")
        return
    out, pat = args[1], (args[2].lower() if len(args) > 2 else "")
    os.makedirs(out, exist_ok=True)
    n = 0
    for name, offset, length in entries:
        if pat and pat not in name:
            continue
        _, comp, dlen, payload = entry_body(data, offset, length)
        if comp in (2, 4):
            payload = lzo1x_decompress(payload, dlen)
        elif comp != 0:
            print(f"skip {name}: unknown compression {comp}", file=sys.stderr); continue
        open(os.path.join(out, name), "wb").write(payload)
        n += 1
    print(f"extracted {n} files to {out}")

if __name__ == "__main__":
    main()
