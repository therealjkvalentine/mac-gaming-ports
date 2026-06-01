# MechWarrior 4: Mercenaries - Apple Silicon (does NOT work on the free stack)

Status: **Does not run on Apple Silicon via Wine.** Documented here so the dead end is on record.
Free MekTek release (Microsoft-sanctioned, 2010). Engine: 2002, 32-bit, DirectX 8. No DRM (freeware).

> The appeal: MW4: Mercenaries has true **native LAN** multiplayer - no Steam, no emulator - the ideal
> "two laptops on a plane" game. The catch: it will not start on Apple Silicon under free Wine.

## What works
- Free download: the MekTek release is on the [Internet Archive](https://archive.org/details/mek-tek)
  (~1.7 GB RAR). Extract with `unar`, **not** `7z` - 7z's RAR codec drops ~1300 files; `unar` is clean.
  It is pre-extracted game files (`MW4Mercs.exe` at the root), no installer.
- 32-bit launches: Sikarugir's Wine 10 starts the 32-bit exe via experimental wow64 (MoltenVK comes up),
  confirming 32-bit-on-Apple-Silicon is viable in general.

## Why it doesn't run: the GetProcessorDetails crash
MW4 crashes at startup: `Fatal Error: Nested exception! - Cause: 'GetProcessorDetails'` /
`Attempt to read from address 0x00000094`. That is MW4's ancient CPU-detection code null-dereferencing.

It is **not fixable with Wine config** - proven by an autosolver that cycled Windows version
(XP/2000/98/7), CPU core count (`WINE_CPU_TOPOLOGY=1:0`), and a registry CPU-name spoof. Even after the
CPU registry verifiably read `Pentium 4`, the crash was byte-identical. So MW4 is **not** reading the
registry; it does low-level CPU detection (CPUID / a system call) that fails under the Rosetta + wow64
translation, where the CPU identifies as `VirtualApple @ 2.50GHz`.

## Options (none are free + easy)
1. **winerosetta** ([Gcenx](https://github.com/Gcenx/winerosetta)) - a shim for x86 instructions Rosetta
   misses on Apple-Silicon Wine. Built for legacy 32-bit WoW; may not bite a logic null-deref, but the
   cheapest first try.
2. **A Wine 11 engine** - reworked wow64; may present CPU info without tripping the bug.
3. **Binary-patch `MW4Mercs.exe`** - NOP the failing CPU-detection call. Surgical, permanent, DIY.
4. **A real x86 VM** (UTM / QEMU, free) - a genuine x86 CPU makes CPUID work and MW4 just runs; native
   LAN works inside the VM. Heavy and slower, but guaranteed. The same VM would also host 2005-NFS LAN.
5. **A Windows laptop** - MW4 is native there and LAN is trivial. The pragmatic group answer.

## The Mac alternative
Since the Mac cannot run MW4, the mech-LAN-on-Mac answer is **MechWarrior 5 + Goldberg LAN** (see that
entry) - it runs flawlessly. Keep MW4 for any Windows machines in the group.
