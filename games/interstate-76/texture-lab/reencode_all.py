#!/usr/bin/env python3
"""Phase 3: rebuild every pak/loose-file from the manifest using ENHANCED tiles
(phase 2's upscaled staging folder, same filenames, any resolution - we resample
back to the ORIGINAL w/h, which is the engine's hard ceiling).

VQM re-encode: quantizes to t01.act (this repo's existing convention - see
texture-lab/README) and writes a fresh PRIVATE codebook per source pak (never
touches shared originals - HD-TEXTURES-RESEARCH.md's rule).
M16 re-encode: fresh per-tile RGB565 palette - no quantization loss at all.
MAP re-encode: quantizes to t01.act, output is a plain .map (no pak needed).

Usage: python reencode_all.py MANIFEST.json ENHANCED_STAGING_DIR ASSETS_DIR OUT_DIR
"""
import os, sys, json, struct, time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools"))
import i76img
from PIL import Image

manifest_path, enhanced_dir, assets, outdir = sys.argv[1:5]
os.makedirs(outdir, exist_ok=True)
manifest = json.load(open(manifest_path))
pal = i76img.read_act(os.path.join(assets, "t01.act"))
t0 = time.time()

_enh_cache = {}
def enhanced_rgba(staged_name, w, h):
    im = _enh_cache.get(staged_name)
    if im is None:
        path = os.path.join(enhanced_dir, staged_name)
        if not os.path.exists(path):
            path = os.path.join(enhanced_dir, staged_name.replace(".png", "_out.png"))
        im = Image.open(path)
        _enh_cache[staged_name] = im
        if len(_enh_cache) > 64:  # bound memory; PIL lazy-loads so this is cheap anyway
            _enh_cache.pop(next(iter(_enh_cache)))
    if im.size != (w, h):
        im = im.resize((w, h), Image.LANCZOS)
    return im.convert("RGBA")

n_done = n_err = 0
for rec in manifest:
    try:
        if rec["kind"] == "pak":
            codebook = ({}, [])
            parts, pix_lines, off = [], [], 0
            for e in rec["entries"]:
                enh = enhanced_rgba(e["staged"], e["w"], e["h"])
                if e["ext"] == ".m16":
                    v = i76img.encode_m16(enh.tobytes(), e["w"], e["h"], e["flags"] or 0)
                elif e["ext"] == ".map":
                    idx = i76img.quantize_to_palette(enh.tobytes(), e["w"], e["h"], pal)
                    v = i76img.encode_map(idx, e["w"], e["h"])
                else:  # .vqm
                    idx = i76img.quantize_to_palette(enh.tobytes(), e["w"], e["h"], pal)
                    cbk_name = os.path.splitext(rec["pak"])[0].upper()[:8] + ".CBK"
                    v = i76img.encode_vqm(idx, e["w"], e["h"], cbk_name, codebook)
                parts.append(v); pix_lines.append((e["name"], off, len(v))); off += len(v)
            base = os.path.join(outdir, os.path.splitext(rec["pak"])[0])
            open(base + ".pak", "wb").write(b"".join(parts))
            with open(base + ".pix", "w", newline="") as f:
                f.write(f"{len(pix_lines)}\r\n")
                for n, o, l in pix_lines:
                    f.write(f"{n.upper()} {o} {l}\r\n")
            if codebook[1]:
                cbk_name = os.path.splitext(rec['pak'])[0].upper()[:8] + ".CBK"
                open(os.path.join(outdir, cbk_name.lower()), "wb").write(
                    struct.pack("<I", len(codebook[1])) + b"".join(codebook[1]))
        elif rec["kind"] == "loose_map":
            e = rec["entries"][0]
            enh = enhanced_rgba(e["staged"], e["w"], e["h"])
            idx = i76img.quantize_to_palette(enh.tobytes(), e["w"], e["h"], pal)
            body = struct.pack("<2I", e["w"], e["h"]) + bytes(idx)
            open(os.path.join(outdir, rec["file"]), "wb").write(body)
        elif rec["kind"] == "loose_m16":
            e = rec["entries"][0]
            enh = enhanced_rgba(e["staged"], e["w"], e["h"])
            v = i76img.encode_m16(enh.tobytes(), e["w"], e["h"], e["flags"] or 0)
            open(os.path.join(outdir, rec["file"]), "wb").write(v)
        n_done += 1
    except Exception as ex:
        n_err += 1
        print(f"ERR {rec.get('pak') or rec.get('file')}: {ex}", file=sys.stderr)
    if n_done % 100 == 0 and n_done:
        print(f"  ...{n_done}/{len(manifest)} rebuilt ({time.time()-t0:.0f}s)", flush=True)

print(f"DONE: {n_done} rebuilt, {n_err} errors, -> {outdir}  ({time.time()-t0:.0f}s)")
