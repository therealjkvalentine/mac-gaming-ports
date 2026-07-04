# Interstate '76 (GOG Gold) - Apple Silicon (port in progress)

Status: **Playable on the free stack** (Sikarugir Wine 10, wow64) - windowed, stable, well-behaved
window, built-in 20 FPS physics limiter. Launch flags: **`-gdi`** (see below - this is the key to
the whole port). FPS-cap/physics verification in progress; dgVoodoo hardware-Glide upgrade is the
open follow-up. Not a Steam title - GOG release, so no SteamCMD: you supply the game files
yourself (see [game-data/](game-data/)).

Engine: 1997, 32-bit. Renderer tokens baked into the exe: `glide` (ZGLIDE -> bundled OpenGLide ->
OpenGL), `d3d`, `redline` (software), `powervr`, and an undocumented **`gdi`** (windowed software
blit - added/fixed by the AiO patch). No DirectX 11 anywhere - D3DMetal is irrelevant (set
`D3DMETAL=0`).

## Why `-gdi` and not `-glide` (the fullscreen-minimize saga)

`-glide` renders and plays, BUT the 2D shell grabs **DirectDraw exclusive fullscreen**, and Wine
has minimized fullscreen-exclusive windows on focus loss since 1.7.32 (hardcoded in wined3d - no
registry off-switch in this build; the X11 `UseTakeFocus` workaround doesn't exist on winemac).
On top of that, winemac's restore-from-minimize for such windows is slow/unreliable (a known Wine
issue), and winemac has no real virtual-desktop support to absorb it. Symptom: the window draws
once, then vanishes to (-16000,-16000) within a few hundred ms every time focus moves - unusable
on a Mac where other apps (especially fullscreen ones on their own Space) constantly hold focus.

`-gdi` runs the whole game (shell + sim) as a **plain window with no exclusive anything** - the
minimize logic never engages, and the window behaves like any Mac window. The software renderer
at 640x480 looks period-correct and clean; the built-in 20 FPS limiter applies the same.

## Colors: `-gdi` looks darker/more saturated than Windows (renderer difference, not a setting)

The two renderers produce different color, and it's inherent:

- **Windows / OpenGLide `-glide`:** Glide pipeline with the emulated **3dfx gamma lift** (~1.3
  hardware gamma every 3dfx-era game was tuned around) + bilinear filtering. Bright, correct for
  daytime SW desert. Our own early Mac `-glide` captures match Windows almost exactly - so the
  hardware path is faithful; it's specifically `-gdi` that shifts.
- **Mac `-gdi`:** the 8-bit palettized software renderer. No gamma lift, no filtering -> darker,
  more saturated, chunkier. This is what we run, because `-glide`'s ddraw exclusive-fullscreen
  triggers Wine's minimize-on-focus-loss (above).

**dgVoodoo2 upgrade - SOLVED (2026-07-04, second attempt).** The first attempt with dgVoodoo
2.87.3 dead-ended (crash at first present); the fix turned out to be three conditions at once:
**dgVoodoo ≤2.8.2** (2.81+ has a Wine-fatal enumeration regression), **DXVK instead of wined3d**
(swap the engine's `d3d11.dll`/`d3d10core.dll` for the copies in
`Contents/Frameworks/renderer/dxvk/wine/`), and **wrap Glide only, not DDraw** (two dgVoodoo
swapchains stack invisibly in one winemac window -> black screen). The shipping config: shell on
Wine's builtin ddraw, sim on dgVoodoo 2.78.2 Glide -> DXVK -> MoltenVK at 1280x960 windowed,
`FPSLimit=20` stacked on the exe's own limiter, **bright 3dfx-gamma colors matching the Windows
build** (screenshot-verified). Full battle log, root causes, and pick-up points:
[docs/DXGI-DGVOODOO-RESEARCH.md](docs/DXGI-DGVOODOO-RESEARCH.md).

Launch flags are now **`-glide`** (the wrapper is set). The `-gdi` build remains the zero-quirk
fallback: `plutil -replace "Program Flags" -string '-gdi' .../Interstate76.app/Contents/Info.plist`
- and [`play-bright.sh`](play-bright.sh) compensates its dark software-renderer look with a held
display gamma lift (default 1.3, via [`i76gamma.swift`](i76gamma.swift)) while the game runs.

Sources: [Wine fullscreen focus-loss behavior](https://forum.winehq.org/viewtopic.php?t=20646),
[SDL issue on the broken restore](https://github.com/libsdl-org/SDL/issues/5320),
[winemac virtual-desktop limitation](https://forum.winehq.org/viewtopic.php?t=40541).

## Discovery: the GOG 2019 build IS the AiO patch (limiter included)

The GOG Gold `i76.exe` (2019-09-01, MD5 `60abf7bc...`) is **byte-identical** to UCyborg's
AiO Unofficial Patch final build (09/01/2019), and the install ships `I76PATCH.DLL` - the AiO's
**built-in frame limiter, hardcoded to 20 FPS** (QueryPerformanceCounter + Sleep, no config file).
So the physics-correct cap is already inside this exe on every platform. The Windows-side notes
("no cap configured") predate this discovery; the dgVoodoo `FPSLimit = 20` there was belt+braces.
The exe also contains a `toggle_framerate` KEYBOARD.MAP action (not in the stock map) - bind it
to get an in-game FPS readout:

```
toggle_framerate     {
   + keyboard     Zero
   - keyboard     Shift
   - keyboard     Control
}
```

## The working recipe (what got it this far)

1. Clone any Sikarugir Wine-10 wrapper (APFS `cp -c`), gut the old game from the prefix.
2. Unzip the GOG install to `drive_c/GOG Games/Interstate 76/` (the zip's backslash paths
   convert cleanly; `unzip` exits 1 with a warning - harmless).
3. `Info.plist`: `Program Name and Path` = `C:\GOG Games\Interstate 76\i76.exe`,
   `Program Flags` = `-gdi` (NOT `-glide` - see the saga above), `D3DMETAL` = `0`.
4. Registry (per-app): `HKCU\Software\Wine\AppDefaults\i76.exe` -> `Version` = `win98`.
5. **Registry: a Wine virtual desktop is REQUIRED** - without it the game page-faults at
   `01B82C26` (it calls `NtUserChangeDisplaySettings`, macOS refuses exclusive 640x480, the game
   dereferences null): `HKCU\Software\Wine\AppDefaults\i76.exe\Explorer` -> `Desktop` = `i76`
   and `HKCU\Software\Wine\Explorer\Desktops` -> `i76` = `1280x960`.
6. **Registry: `HKCU\Software\Wine\Mac Driver` -> `WindowsFloatWhenInactive` = `all`.** Without
   it, the moment another app takes focus (especially a fullscreen app on its own Space), winemac
   treats the desktop window - which exactly equals Wine's virtual screen - as a fullscreen window
   and MINIMIZES it (parks it at -16000,-16000). Symptom: the game window appears, draws once,
   and vanishes within a few hundred ms. This key makes it float like a normal window.
7. Launch via the wrapper (`open .../Interstate76.app`).

Do NOT force `renderer=gdi` for ddraw - the shell creates a Direct3D device and crashes at the
same address if refused. The default wined3d GL path works (one harmless
`GL_INVALID_FRAMEBUFFER_OPERATION` at startup).

Quirks seen on Mac so far:

- The **sim pauses when the app loses focus**; menus, cinematics, and the pause menu keep
  rendering and keep accepting input (even input posted directly to the process). Fine for
  play; matters for automation.
- Mouse hit-testing is offset in the scaled virtual desktop (the known 640x480 internal-coords
  quirk) - navigate menus by keyboard: arrows + Enter, numbers pick menu items.
- Do not maximize/zoom the virtual-desktop window; dragging it is fine. (The
  flash-and-vanish-on-refocus bug is fixed by `WindowsFloatWhenInactive` - step 6.)
- **CLI launches must set `WINEMSYNC=1` alongside `WINEESYNC=1`** (the wrapper's launcher sets
  both; msync wins). esync-only sends every Wine process (explorer, 2x winedevice, the game) into
  a 100%-CPU busy-spin on macOS. With msync, all of them idle at ~0-4%.
- Never kill the prefix's `explorer.exe` while playing - it's the Wine session shell/clipboard
  manager; the game exits shortly after it dies.
- `wow64_NtSetLdtEntries` stub warning at startup is harmless (unlike MW4, nothing depends on it).
- Wine-level FPS measurement: relaunch from CLI with `WINEDEBUG=-plugplay,+fps,+timestamp` and
  watch `wglSwapBuffers` lines. The 2D shell/menus tick at ~14-15 fps by design (the AiO limiter
  also throttles menus/cutscenes to save CPU).

## THE ONE RULE: cap the game at ~20 FPS or the physics break

I76 ties physics/AI/scripted events to the render framerate (fixed-timestep assumption from 1997;
confirmed by the reverse-engineering community - no 60fps patch exists). Above ~30 FPS: cars flip,
Mission 5's ramp jump becomes impossible, the flamethrower/mortar break, AI caps at 35 mph.
Community consensus cap = **20 FPS** (24-25 ok, 30 = loose ceiling).

- On Windows this was fixed with dgVoodoo2 `FPSLimit = 20` - verified across ~40 min of melee +
  campaign play, zero crashes. Config in [docs/WHAT-THIS-IS-dgvoodoo.txt](docs/WHAT-THIS-IS-dgvoodoo.txt).
- On macOS there is **no verified equivalent limiter** - that is the entire challenge of this port.

Do not campaign uncapped. Verify the cap first (checklist below).

## The paths (from the handoff research)

- **Path A - Wine wrapper** (this repo's stack; trying first). 32-bit exe under Wine 10,
  `i76.exe -glide` through the bundled OpenGLide (Glide -> OpenGL). Cap candidates, in order:
  the **AiO Unofficial Patch** (PCGW Community file #1349 - built-in 20 FPS limiter + crash/audio
  fixes; compat with the 2019 GOG exe unverified - back up first), or **nGlide + DXVK** with
  `DXVK_FRAME_RATE=20` (coherent but untested chain).
- **Path B - 86Box** (physics-correct by construction): Pentium 200 MMX + Voodoo 1 (2MB+2MB) +
  Win95 OSR2, install from the CD ISO. Era-accurate speed can't break the physics; save states.
  Needs a Win95 license; the one recent report used software rendering at 5-10 fps - the
  Voodoo/Glide config should be much better but is untested.
- **Path C - stream from the Windows box** (zero-risk fallback, already fully working there):
  Sunshine host + Moonlight client, Ethernet. A 20fps game makes stream latency irrelevant.

Full handoff brief: [docs/MAC-SETUP.md](docs/MAC-SETUP.md). Deep research with sources:
[docs/i76-research-full.txt](docs/i76-research-full.txt). Windows-side notes:
[docs/MODERN-SETUP.md](docs/MODERN-SETUP.md).

## Controls: Mac arrow keys (required fix)

winemac delivers Mac arrow keys as the game's `Grey*` (numpad-cluster) codes; the stock
`KEYBOARD.MAP` binds those to glance/track camera and puts **driving** on the plain arrow names
Mac arrows never produce - so arrows look around instead of steering. Run
[`fix-arrows-for-mac.sh`](fix-arrows-for-mac.sh) on the `KEYBOARD.MAP` in your game folder
(it swaps the four arrow tokens; backup written beside it; restart the game). Glance/track land
on the numpad - still reachable on a full-size external keyboard.

## Controls: the MW5-style laptop layout

[`KEYBOARD.MAP.mw5`](KEYBOARD.MAP.mw5) - drop-in replacement for the game's `KEYBOARD.MAP`
(back up the original first). W/S notched throttle, A/D steer, Space fire, Tab weapon cycle,
X reverse, C handbrake, I ignition, arrows glance. Not yet play-tested - verify in Instant Melee.
Quirk: bare Shift can't be a primary key (the parser treats it as a modifier).

## Verify-the-cap checklist (any path)

1. Instant Melee (MELEE -> AUTO MELEE -> INSTANT MELEE -> ENTER AREA): no flips on bumps, car
   settles after banking, AI cars can exceed 35 mph.
2. Game speed sane (cutscenes not fast-forwarded, no Benny-Hill effect).
3. The canonical full test: Mission 5's ramp jump.

## Hard-won facts (from the Windows sessions)

- **i76fix (github immi101) does NOT fit this 2019 GOG exe** - it blind-patches offsets for the
  2017 build (MD5 `9a232dcc...`) and would corrupt this one (`60abf7bc...`).
- Boot takes 60-75s of "PLEASE STAND BY" + intro; ESC (sometimes twice) skips.
- Throttle is NOTCHED (set-and-hold, like a mech) - tap W, don't hold.
- Menus hit-test the mouse in internal 640x480 coords offset from the window origin, unscaled;
  the in-sim pause menu is keyboard-only under wrappers (arrows + Enter).
- Known cosmetic jank under Wine (AppDB): garbled menu on first launch, menu bar turning black
  after missions - navigate by keyboard.
- Deep-campaign bugs (fixed by the AiO patch): mission 12->13 transition crash; restart the game
  around missions 14-15 on long sessions.
- Campaign mission 1 = "Follow Taurus to Seagraves": tight follow leash (~40-60s separation =
  fail); the road from the diner is one long gentle LEFT arc.
- interstate76.com forums are dead (2026) - source patches from PCGW Community #1349, VOGONS
  t=68384, or archive.org.

## Get the game

Buy [Interstate '76 on GOG](https://www.gog.com/game/interstate_76) (I76 Gold includes the Nitro
Pack). Then see [game-data/README.md](game-data/README.md) for what to place where - the repo
contains no game files.
