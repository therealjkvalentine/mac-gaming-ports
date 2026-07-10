# Interstate '76 on Apple Silicon — every verified fix, one table

*The fast-discovery index for future travelers. Each row was **hit, diagnosed, and fixed (or
measured) on this port** — not speculation. Deep dives live in the linked docs; this page is the
map. Stack: GOG Gold (2019 exe) + Sikarugir Wine 10 (wow64) wrapper, Apple Silicon, no CrossOver.*

## Crashes / freezes / hangs

| Symptom | Root cause | Fix |
|---|---|---|
| Page fault at `01B82C26` at boot | Game calls `NtUserChangeDisplaySettings`; macOS refuses exclusive 640x480; game derefs null | Per-app Wine **virtual desktop**: `HKCU\Software\Wine\AppDefaults\i76.exe\Explorer → Desktop=i76`, `HKCU\Software\Wine\Explorer\Desktops → i76=1280x960` |
| Multi-second freezes in menus/missions, then **stack-overflow crash**; also silent mission music | Launch env missing **GStreamer plugin paths** → winegstreamer can't decode MP3 → MCI open fails → game retries in a tight loop | Set `GST_PLUGIN_PATH`, `GST_PLUGIN_SYSTEM_PATH_1_0`, `GST_PLUGIN_SCANNER_1_0`, `GST_REGISTRY_1_0` + GStreamer libs on `DYLD_FALLBACK_LIBRARY_PATH` (see [i76-launch-stub.swift](../i76-launch-stub.swift)) |
| Crash at `i76+0x4507C` in `-glide` (OpenGLide) when launched by the stock wrapper launcher | Stock Sikarugir launcher exports `CX_FWD_COMPAT_GL_CTX=1` (forward-compatible GL context kills legacy GL) **and** sets a wrong CWD (hides `OpenGLid.INI`/`dgVoodoo.conf`, which are CWD-discovered) | Replace the launcher with our Mach-O stub (env + correct CWD) |
| Every Wine process pinned at **100% CPU** | `WINEESYNC=1` alone busy-spins on macOS | Set **both** `WINEESYNC=1` and `WINEMSYNC=1` (msync wins; all procs idle at ~0-4%) |
| dgVoodoo crash at present-time (`0x79F119BD`) with dgVoodoo ≥ 2.81 | 2.81+ adapter-enumeration regression under Wine (dxvk#5217 / wine bug 58731) | Use **dgVoodoo 2.78.2** |
| Defensive: 1 MB stack is tight for this engine under Wine | 1997-era `SizeOfStackReserve` | PE patch OptionalHeader+0x48 → 8 MB (backup kept: `i76.exe.pre-stackpatch`) |

## Window / display

| Symptom | Root cause | Fix |
|---|---|---|
| Window draws once then **vanishes to (-16000,-16000)** on any focus loss | Wine hardcodes minimize-on-focus-loss for exclusive-fullscreen ddraw (since 1.7.32; no off-switch) | Don't run exclusive fullscreen: DxWnd windowed path. Mitigation if you must: `HKCU\Software\Wine\Mac Driver → WindowsFloatWhenInactive=all` |
| Tiny fixed 640x480 window (`-gdi`) | That renderer doesn't scale | **DxWnd** (default): scales the software render into a big resizable title-barred window |
| Fullscreen-ish stretch instead of 4:3 | Wrong DxWnd position mode | Profile: `coord0=3` (Desktop) + **Keep aspect ratio** (`flagg0` bit 0x10) + Hide desktop (`flagi0` bit 0x8000) → letterboxed 4:3 filling the screen. `Adaptive ratio` = stretch, leave OFF. Video-tab "Fix aspect ratio" is NOT letterboxing. See [DXWND-TUNING.md](DXWND-TUNING.md) |
| Black menus/cutscenes under DxWnd | Emulated blit renderers | DirectX tab **Renderer = primary surface** (`renderer0=3`) — note: upscale filters only work on emulated renderers, so filters and this fix are in tension |
| **Black "wine" window survives quitting; force-quit needed** | Two-part: DxWnd host stays resident after the game dies (so a launcher waiting on `dxwnd.exe` never reaps) + the HideDesktop backdrop ("hider" window) belongs to processes `wineserver -k` alone may miss | Stub waits for **`i76.exe`** to exit (not dxwnd), then `wineserver -k` + `pkill -f <bundle>/Contents/SharedSupport` sweep. Verified: 0 processes, 0 windows within 10 s |

## Launch plumbing (macOS specifics)

| Symptom | Root cause | Fix |
|---|---|---|
| DxWnd GUI opens instead of the game with `/r:0` | `/R` is **1-based** (source: `iProgIndex-1`) | `dxwnd.exe /R:1` for headless one-click launch. Do **not** add `/q` — it suppresses the launch |
| Blank never-painting window when stub `execv`s wine | `execv` breaks winemac GUI activation under LaunchServices | Spawn wine as a **child Process** from the stub |
| .app won't launch from Finder with a script as the executable | LaunchServices refuses script bundle executables | Compile a small **Mach-O** stub |
| `codesign --deep` fails on the wrapper | Chokes on internal symlinks | Sign the stub binary alone |
| macOS asks for **microphone permission** at launch | Wine's CoreAudio driver opens the default *input* device during audio init | Harmless — **Deny is fine**; audio output is unaffected |

## Audio / music

| Symptom | Root cause | Fix |
|---|---|---|
| Music in cutscenes but **silent in missions** | Mission music = CD **redbook audio**; GOG ships it as `music/N.mp3` + an *empty* `tracklen.nfo`; no CD to play under Wine | DxWnd **virtual CD audio** (`flagm0` bit 0 → dxwplay.dll) + hard-link tracks to its expected `Music\TrackNN.mp3` naming + delete the empty `tracklen.nfo` (it regenerates). Script: [setup-music.sh](../setup-music.sh). Requires the GStreamer env above. **Confirmed in-mission** |

## Input

| Symptom | Root cause | Fix |
|---|---|---|
| Mac arrow keys glance/track camera instead of steering | winemac delivers Mac arrows as the game's `Grey*` (numpad) codes; stock `KEYBOARD.MAP` puts driving on plain-arrow names Macs never send | [fix-arrows-for-mac.sh](../fix-arrows-for-mac.sh) swaps the four arrow tokens in `KEYBOARD.MAP` |
| Mouse clicks land in the wrong place in menus | Game hit-tests in internal 640x480 coords; scaling paths (virtual desktop, DxWnd) offset it | Navigate menus by keyboard (arrows + Enter). Synthetic/automated clicks are ignored entirely through DxWnd scaling |
| Force feedback (wheel) silent | Game FFB is real (Nitro Pack, in GOG Gold, off by default) but Wine's only FFB backend is **Linux evdev** — no macOS path exists | No Mac fix. On a Windows box: run [enable-force-feedback.bat](../enable-force-feedback.bat) (registry key copy) and FFB works on modern wheels. See [FORCE-FEEDBACK-AND-VISUALS.md](FORCE-FEEDBACK-AND-VISUALS.md) |

## Performance / visuals (measured ceilings)

| Fact | Detail |
|---|---|
| **20 FPS cap ships in the GOG exe** | GOG 2019 `i76.exe` is byte-identical to UCyborg's AiO patch; `I76PATCH.DLL` = built-in 20 FPS physics limiter. **Measured ~20.66 FPS in-sim** — physics-safe with no external limiter |
| **1024x768 = software renderer max** | Menu maxes there because the engine does; no config/registry/hex unlock found; D3D mode is locked 640x480. DxWnd upscales output beyond it |
| Camera is hardcoded 4:3 | No widescreen exists; "fill screen" = big 4:3 + black bars |
| Higher *internal* res needs Glide | dgVoodoo 2.78.2 (Glide→D3D11→DXVK→MoltenVK) renders 2x+ with 3dfx gamma — the "Voodoo" launcher. Cost: pipeline-compile warmup on first-seen content (SPIRV→MSL); mitigations: DXVK async + state cache (warm after a break-in run); true fix in progress: persist the VkPipelineCache |
| dgVoodoo under Wine needs 3 conditions | ≤2.78.2 + **DXVK** d3d11 (wined3d refuses FL10.1 on GL and Vulkan) + wrap **Glide only** (wrapping ddraw too = dual swapchains stacking invisibly in winemac). Full saga: [DXGI-DGVOODOO-RESEARCH.md](DXGI-DGVOODOO-RESEARCH.md) |

## Where everything lives

- Launchers: [build-launchers.sh](../build-launchers.sh) → `Interstate76.app` (DxWnd default), `I76 Voodoo.app` (dgVoodoo Glide), `I76 DxWnd Settings.app` (GUI)
- DxWnd: [setup-dxwnd.sh](../setup-dxwnd.sh) + profile [interstate-76.dxw](../interstate-76.dxw); settings map: [DXWND-TUNING.md](DXWND-TUNING.md)
- Research compendia: [RUNNING-I76-EVERYWHERE.md](RUNNING-I76-EVERYWHERE.md), [DXGI-DGVOODOO-RESEARCH.md](DXGI-DGVOODOO-RESEARCH.md), [FORCE-FEEDBACK-AND-VISUALS.md](FORCE-FEEDBACK-AND-VISUALS.md)
