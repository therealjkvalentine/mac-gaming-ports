# Interstate '76 (GOG Gold) - Apple Silicon (port in progress)

Status: **Playable on the free stack** (Sikarugir Wine 10, wow64), built-in 20 FPS physics
limiter. **Default: `-glide`** - the game's own Glide renderer through the GOG-bundled OpenGLide
(Glide -> OpenGL): bright 3dfx-gamma colors, 1280x960 window, instant start, no shader warmup.
One quirk: alt-tabbing away minimizes the window (Wine behavior for exclusive-fullscreen apps);
it auto-restores on refocus. **Fallback: `-gdi`** - small (640x480), darker, but a completely
normal window with zero quirks. Pick via **I76 Launcher.app** (below). Not a Steam title - GOG
release, so no SteamCMD: you supply the game files yourself (see [game-data/](game-data/)).

**Disk use (~4.1 GB for a ~470 MB game):** the wrapper is self-contained - Wine engine (~760 MB) +
the C: drive prefix (~2.8 GB: Windows system DLLs, fonts, registry, the DXVK shader caches) +
D3DMetal/DXVK/MoltenVK frameworks (~340 MB) + the game itself (~470 MB). That's the price of a
portable, no-dependencies `.app`; the game data is the small part.

Engine: 1997, 32-bit. Renderer tokens baked into the exe: `glide` (ZGLIDE -> bundled OpenGLide ->
OpenGL), `d3d`, `redline` (software), `powervr`, and an undocumented **`gdi`** (windowed software
blit - added/fixed by the AiO patch). No DirectX 11 anywhere - D3DMetal is irrelevant (set
`D3DMETAL=0`).

## The two modes

| | **Glide (default)** | **Classic `-gdi` (fallback)** |
|---|---|---|
| Renderer | game's Glide -> bundled OpenGLide -> OpenGL | 8-bit software blit |
| Look | **bright 3dfx-gamma colors, filtered** (matches Windows) | darker, chunkier, period-correct |
| Window | 1280x960 (the Wine virtual-desktop size) | fixed 640x480 |
| Start | instant - no shader warmup (plain OpenGL path) | instant |
| Quirk | **alt-tab minimizes the window; auto-restores on refocus** (Wine's hardcoded behavior for exclusive-fullscreen ddraw apps - the shell holds that mode; mitigations `WindowsFloatWhenInactive=all` + msync are in the recipe) | none - completely normal window |

**Which mode am I running?** `ps ax | grep i76.exe` shows the flag. Visual tells: bright + big
window = Glide; dark + small = `-gdi`.

**Window size:** the Glide window tracks the Wine virtual-desktop registry size (recipe step 5;
default `1280x960` - change `HKCU\Software\Wine\Explorer\Desktops -> i76` and restart). `-gdi`
is fixed 640x480 (engine limit). **No fullscreen in either mode**: Wine windows don't
participate in macOS fullscreen (`AXFullScreen` unsupported), and avoid the green zoom button.
macOS screen zoom (Accessibility) works in a pinch.

**Colors/gamma:** the game itself sets the 3dfx gamma through the Glide API, and OpenGLide
honors it - that's why Glide mode is bright out of the box. There is no gamma knob in
`OpenGLid.INI` or the `-gdi` path; use the game's own brightness (Options -> Graphic Detail) to
taste in either mode.

## Launching & picking modes (GUI)

Build the chooser app once:
```sh
osacompile -o "$HOME/Applications/Sikarugir/I76 Launcher.app" I76-Launcher.applescript
```
**I76 Launcher.app** presents *Glide (bright, 1280x960)* / *Classic (small, zero quirks)* /
*Quit running game* - it sets the wrapper's launch flag and opens it. CLI: [`play.sh`](play.sh)
launches whatever mode is currently set; flip modes with
`plutil -replace "Program Flags" -string '-gdi' ~/Applications/Sikarugir/Interstate76.app/Contents/Info.plist`
(or `'-glide'`).

## The dgVoodoo detour (retired - kept for the record)

We spent a day making dgVoodoo 2.78.2 + DXVK render the sim (it works - three hard-won
conditions documented in [docs/DXGI-DGVOODOO-RESEARCH.md](docs/DXGI-DGVOODOO-RESEARCH.md)), then
retired it: **plain OpenGLide already renders the sim just as bright** (the game sets 3dfx gamma
via Glide either way), **without** dgVoodoo's ~2-min-per-launch shader warmup (uncacheable on
this stack: needs a cereal-built MoltenVK *and* a DXVK that persists `VkPipelineCache`) and
**without** its launch fragility (dgVoodoo reads its conf from the CWD, which `open` gets wrong).
Net value of dgVoodoo here: zero; the research is preserved because the Wine-DXGI findings are
reusable and the hybrid is the fallback if the OpenGLide path ever breaks in a future Wine.

Sources: [Wine fullscreen focus-loss behavior](https://forum.winehq.org/viewtopic.php?t=20646),
[SDL issue on the broken restore](https://github.com/libsdl-org/SDL/issues/5320),
[winemac virtual-desktop limitation](https://forum.winehq.org/viewtopic.php?t=40541).

## Discovery: the GOG 2019 build IS the AiO patch (limiter included)

The GOG Gold `i76.exe` (2019-09-01, MD5 `60abf7bc...`) is **byte-identical** to UCyborg's
AiO Unofficial Patch final build (09/01/2019), and the install ships `I76PATCH.DLL` - the AiO's
**built-in frame limiter, hardcoded to 20 FPS** (QueryPerformanceCounter + Sleep, no config file).
So the physics-correct cap is already inside this exe on every platform. The Windows-side notes
("no cap configured") predate this discovery; the dgVoodoo `FPSLimit = 20` there was belt+braces.
(The exe contains a `toggle_framerate` KEYBOARD.MAP action string, but binding it - tried with
`Zero` - produced no visible effect, and if it does anything it more likely toggles the *limiter*
than a counter. Don't bind it. For an FPS readout in `-glide` mode use the DXVK HUD instead:
`dxvk.conf` next to the exe with `dxvk.hud = fps,compiler` - `compiler` also visualizes the
per-launch async-shader warmup, see quirks.)

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
- **`-glide` warmup: the first ~2 minutes of each session run at a slideshow pace** while
  DXVK-async + MoltenVK compile the sim's shaders (this MoltenVK has no persistent shader cache,
  so the Metal-side compile repeats per launch; the `i76.dxvk-cache` next to the exe shortens it
  as it grows). Brief hitches on first-seen effects (first explosion, first smoke) are the same
  thing and stop recurring within the session. Let it warm up in the menu/first mission start.

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
