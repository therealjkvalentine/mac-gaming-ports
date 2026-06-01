# MechWarrior 4: Mercenaries - Apple Silicon (works, with a runtime patch)

Status: **Boots to a stable menu** on Apple Silicon via a runtime memory patch + windowed mode -
verified headless (55s alive, zero crashes). Free MekTek release. Engine: 2002, 32-bit, DirectX 8. No DRM.
Gameplay (missions / native LAN) not yet exercised end-to-end - see caveats.

> This is the repo's one title that needed a binary fix. The startup crash is defeated by a runtime
> memory patch (the exe is packed, so it's patched in RAM, not on disk), and the fullscreen failure is
> dodged by running in a Wine virtual desktop.

## Get the game
Free MekTek release on the [Internet Archive](https://archive.org/details/mek-tek) (~1.7 GB RAR).
Extract with `unar` (NOT 7z - its RAR codec drops files). Pre-extracted game files, no installer.

## Launch
```sh
zsh ~/Games/MechWarrior4/play-mw4.sh
```
Launches windowed, waits ~5s for the packed code to decompress, attaches with lldb and applies the
startup patch, then the game runs.

## What was wrong, and the fix (the RE)
Startup crash: `GetProcessorDetails` / page fault reading null+`0x94`. winver, CPU-name spoof, and
core-count (`WINE_CPU_TOPOLOGY`) changes did nothing. The exe is **packed** (16 MB virtual `.text` from a
1.4 MB file), so the crash code isn't on disk. Proper RE got it:
1. `lldb` attach to the running game + `memory read` the **decompressed** code (packing is irrelevant in RAM).
2. capstone disassembly pinned the fault: `0x6fabaa: mov cl,[eax+0x94]` - a small routine copying a byte
   from its (null) second argument.
3. Patch in RAM to `xor cl,cl` + NOPs (`8a 88 94 00 00 00` -> `30 c9 90 90 90 90`): use a 0 byte instead
   of dereferencing null. `play-mw4.sh` re-applies this with lldb on every launch.

Second hurdle: a "can't go fullscreen" dialog whose *cleanup* heap-crashed (`SimpleDialogBox`, "free
invalid memory"). Fixed by running windowed (`wine explorer /desktop=...`) so that dialog never appears.

## Native LAN (the point of MW4)
MW4 has built-in LAN multiplayer (Multiplayer -> LAN) - no Steam, no emulator. On a closed router each
machine runs the game (Mac: `play-mw4.sh`; Windows: native), one hosts, the others join. The no-emulator
plane option. (Not yet tested end-to-end on the Mac build.)

## Caveats / not yet verified
- Headless verification confirms "alive + GPU up + no crash for a minute" = a stable menu, not a black
  screen - but the menu *render* and actual *gameplay* aren't visually confirmed yet.
- Going into a mission/Instant Action may surface more null-derefs; they're patchable the same way
  (lldb dump -> capstone -> memory write).
- The patch substitutes a `0` for one byte that routine copied (looked like a string/stat field) - cosmetic.
