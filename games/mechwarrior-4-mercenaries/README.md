# MechWarrior 4: Mercenaries - Apple Silicon (dead end, fully diagnosed)

Status: **Does not run on Apple Silicon.** The free MekTek release is blocked by copy-protection
that programs x86 **LDT segment registers**, which Apple Silicon's Rosetta translation does not
emulate. It runs fine on real x86 (Intel Mac, Windows, Linux). Full CPU emulation (QEMU) clears that
specific wall but isn't practically playable. The complete diagnosis and what could unblock it are below.

Engine: 2002, 32-bit, DirectX 8. Distributed free by MekTek (2010).

## TL;DR
- The exe is **PECompact 2-packed** wrapping **SafeDisc-style protection** that calls
  **`NtSetLdtEntries`** (sets up custom x86 LDT segment descriptors).
- Apple Silicon runs x86 via **Rosetta 2**, which emulates only FS/GS segment bases (for thread-local
  storage) - **not arbitrary LDT segments**. Wine's wow64 therefore stubs `NtSetLdtEntries`; the
  protection's segment accesses fault and the game dies. This is **architectural** - not fixable by
  Wine config or a one-byte patch on Apple Silicon.
- Confirmed working on real x86 under Wine (WineHQ AppDB), where the LDT exists in hardware.

## The full diagnosis (the RE trail)
1. **Packer = PECompact 2** (`PEC2`/`PECompact` strings in the exe; the entry stub installs an SEH
   handler via `push fs:[0]` then deliberately writes to null so the handler runs - SEH-driven
   decompression). This is the "exception storm" of ~50 handled `c0000005`s during startup.
2. **Startup crash `0x6fabaa`**: `mov cl,[eax+0x94]` with a null second arg (a `GetProcessorDetails`
   routine). The exe is packed (16 MB virtual `.text` from 1.4 MB on disk), so the code isn't on disk -
   dumped the decompressed code with `lldb` + disassembled with `capstone`. Patchable in RAM
   (`8a 88 94 00 00 00` -> `30 c9 90 90 90 90`, i.e. `xor cl,cl`). NOTE: this is a hack - it returns 0
   for a CPU-detail byte and appears to cause downstream heap corruption (see the emulation note).
3. **The real wall - `NtSetLdtEntries`**: 4 calls (selectors 0x1107 / 0x2107 / 0x210f), each
   immediately followed by a `c0000005`. Wine's wow64 stubs this on Apple Silicon. On the Mac the game
   dies here, after the EULA, while building its render device.
4. Windows Error Reporting minidumps were all 0 bytes under Wine; the LDT + exception-storm + packing
   pattern is the SafeDisc/PECompact fingerprint.

## Why Rosetta can't fix it
Rosetta translates x86-64 -> ARM64. It emulates FS/GS segment bases (every program needs them for TLS)
but **not** arbitrary LDT-defined DS/ES segment bases - that would require a base-add check on every
memory access for a feature essentially no modern software uses. Real x86-64 honors those bases in
32-bit compatibility mode in hardware, for free. Rosetta is a closed Apple binary and won't gain this;
Wine can't add it either, because the segment accesses are raw instructions Rosetta translates - Wine
never sees them to inject the base arithmetic.

## Emulation experiment (QEMU x86 + Wine) - clears the LDT, still not playable
Built a Debian x86_64 VM under QEMU (TCG = full software CPU emulation) with 32-bit Wine and ran MW4:
- **The LDT wall is gone.** `NtSetLdtEntries` works (real emulated LDT), and with the `0x6fabaa` patch
  the game ran past *both* the startup crash and the render-init that kill it on the Mac. wined3d
  initialized a software device (`llvmpipe`). This confirms the diagnosis: emulation removes the
  architectural wall.
- **But** it then hits a fatal **heap-corruption STOP** ("Attempted to free invalid memory ...",
  Continue greyed out), persisting even windowed. Most likely the crude `0x6fabaa` patch returning bad
  CPU data; a proper fix would rebuild the null processor-info struct the caller fails to pass under
  Wine - deeper RE - and there are probably more walls behind it.
- QEMU has **no 3D acceleration** - it software-renders, so mech combat would be a slideshow regardless.

## What could unblock it in the future
1. **Run on real x86** - Intel Mac, Windows PC, or Linux x86. Native (hardware LDT). MW4 has built-in
   LAN (Multiplayer -> LAN, no Steam/emulator), so for the airplane-LAN goal, run MW4 on a PC.
2. **A de-protected exe** - unpack PECompact *and* strip/neutralize the LDT-based protection, then
   rebuild the import table, producing a flat exe with no `NtSetLdtEntries`. That would run under
   Rosetta+Wine. This is real RE, best done on a real x86 box (x64dbg + Scylla) and the clean exe
   brought back to the Mac. The community no-CD "mini-images" do **not** do this - they are disc-check
   bypasses that leave the packed, protected exe intact.
3. **A QEMU/UTM x86 *Windows* VM** (the game's native environment, vs Linux+Wine) - would run if the
   heap-corruption is resolved, but still software-rendered and slow.
4. **Rosetta/Wine gaining LDT emulation** - not realistic (closed Rosetta; Wine can't intercept it).

## The working alternative for Mac mech-LAN
**MechWarrior 5: Mercenaries** runs hardware-accelerated (D3DMetal) with offline Goldberg LAN - see
[../mechwarrior-5-mercenaries](../mechwarrior-5-mercenaries/). That is the Mac answer; MW4 here is a
research curiosity.

## Get the game (for real-x86 use)
Free MekTek release on the [Internet Archive](https://archive.org/details/mek-tek) (~1.7 GB RAR).
Extract with `unar` (not 7z - its RAR codec drops files).
