# Running MechWarrior 5: Mercenaries on Apple Silicon — free, open-source, no Steam needed

> **What this is:** a complete, reproducible recipe for running **MechWarrior 5: Mercenaries**
> (a Windows-only Steam game) on **Apple Silicon Macs** with **free, open-source tooling** — no
> CrossOver license — and the finished package runs **without Steam installed or running**.
>
> **Verified on:** Apple **M5 Pro**, **macOS 26 (Tahoe)**, May 2026. Should work on any M1–M5 Mac
> running macOS 14–27.
>
> This file doubles as an `AGENTS.md`: it's written so a coding agent (or a human) can reproduce or
> repair the setup from scratch. Read "The gotchas" before changing anything — most obvious paths fail.

---

## TL;DR — how to launch

```sh
open ~/Applications/Sikarugir/MechWarrior5.app
```

No Steam. No Play button. The `.app` is fully self-contained (Wine 10 + Apple D3DMetal + the game).
First launch compiles shaders (slow / black screen for 1–3 min) — normal.

---

## The stack (and why each piece)

| Layer | Choice | Why this and not the obvious thing |
|---|---|---|
| **Wrapper** | **Sikarugir** (free/OSS; the maintained successor to Kegworks → Wineskin) | Produces a self-contained, relocatable `.app`. Actively maintained for Apple Silicon + Tahoe. |
| **Wine** | **Wine 10** (Sikarugir engine `WS12WineSikarugir10.0`) | Apple's Game Porting Toolkit ships **Wine 7.7 (2022)**, which is too old — the current Steam client's Chromium-126 UI crash-loops on it. Wine 10 runs it fine. |
| **Graphics** | **D3DMetal** (Apple's DirectX→Metal, free, from the Game Porting Toolkit; bundled in the Sikarugir engine) | Best DX11/12 performance on Apple Silicon. The open-source alternative (WineD3D→Vulkan→MoltenVK) **fails MW5's "Feature Level 11.0" check**. |
| **Download** | **native macOS SteamCMD** | The Steam client *running inside Wine* stalls on downloads (CDN connections drop after ~2 GB). Native SteamCMD uses the Mac's real networking and never stalls. |
| **Translation** | **Rosetta 2** | The game and Wine are x86-64; Rosetta translates to ARM. Apple has committed to keeping Rosetta for games through macOS 28+. |

---

## Requirements

- Apple Silicon Mac (M1–M5), **macOS 14–27**
- **Rosetta 2**: `softwareupdate --install-rosetta --agree-to-license`
- **Homebrew** (only for the one-time Sikarugir install): https://brew.sh
- **~100 GB free** (MW5 is ~95 GB installed)
- Your **Steam account** that owns MW5 (used once, by SteamCMD, to download)

---

## Full setup from scratch

> If you just received a prebuilt `MechWarrior5.app`, skip all of this — see **Portability** below.

### 1. Install Sikarugir + Rosetta
```sh
softwareupdate --install-rosetta --agree-to-license
brew install --cask Sikarugir-App/sikarugir/sikarugir
xattr -dr com.apple.quarantine "/Applications/Sikarugir Creator.app"   # modern Homebrew dropped --no-quarantine
```

### 2. Build a Wine-10 wrapper
Open **Sikarugir Creator**. In its window:
1. Click **Download Template**.
2. The engine auto-selects **`WS12WineSikarugir10.0`** (Wine 10) — leave it (do NOT use an older one).
3. Click **Create**, name it `MechWarrior5`, save (default location is `~/Applications/Sikarugir/`).

The result is `~/Applications/Sikarugir/MechWarrior5.app`, a self-contained bundle:
- Wine engine: `Contents/SharedSupport/wine/`
- Prefix (the fake C: drive): `Contents/SharedSupport/prefix/`
- D3DMetal: `Contents/Frameworks/renderer/d3dmetal/`
- Launch config: `Contents/Info.plist`

### 3. Download the game with native SteamCMD (NOT the in-Wine Steam)
```sh
mkdir -p ~/Games/MechWarrior5/steamcmd && cd ~/Games/MechWarrior5/steamcmd
curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz | tar xzf -
./steamcmd.sh +quit   # self-update

# Download MW5 (AppID 784080) Windows depots into a temp dir. force_install_dir MUST come before login.
./steamcmd.sh +@sSteamCmdForcePlatformType windows \
  +force_install_dir ~/Games/MechWarrior5/mw5-windows \
  +login YOUR_STEAM_LOGIN +app_update 784080 validate +quit
# (prompts for your password + Steam Guard code; ~38 GB download → ~95 GB installed)
```

### 4. Graft the game into the wrapper
```sh
PFX=~/Applications/Sikarugir/MechWarrior5.app/Contents/SharedSupport/prefix
DEST="$PFX/drive_c/Program Files (x86)/Steam/steamapps/common/MechWarrior 5 Mercenaries"
rm -rf "$DEST"
mv ~/Games/MechWarrior5/mw5-windows "$DEST"     # instant on the same volume
rm -rf "$DEST/steamapps"                          # SteamCMD's own metadata; not needed
```

### 5. Point the wrapper at the game + enable D3DMetal
```sh
APP=~/Applications/Sikarugir/MechWarrior5.app
plutil -replace "Program Name and Path" -string \
  'C:\Program Files (x86)\Steam\steamapps\common\MechWarrior 5 Mercenaries\MW5Mercs\Binaries\Win64\MechWarrior-Win64-Shipping.exe' \
  "$APP/Contents/Info.plist"
plutil -replace "Program Flags" -string '-dx11' "$APP/Contents/Info.plist"
plutil -replace "D3DMETAL"   -integer 1 "$APP/Contents/Info.plist"   # << the critical one (see gotcha #4)
plutil -replace "METAL_HUD"  -integer 0 "$APP/Contents/Info.plist"   # set 1 for an FPS overlay
```

### 6. Launch
```sh
open ~/Applications/Sikarugir/MechWarrior5.app
```

---

## The gotchas (READ THIS — the obvious paths all fail)

1. **GPTK's Wine 7.7 is too old.** Apple's Game Porting Toolkit Homebrew cask ships Wine 7.7; the
   current Steam client's `steamwebhelper` (Chromium 126) crash-loops on it (re-spawns every ~10 s).
   → Use **Sikarugir's Wine 10**.

2. **The in-Wine Steam downloader stalls.** It connects, pulls ~2 GB, then all CDN connections drop and
   it loops "Got N download sources" forever. The Mac's own networking is fine (verified with `curl`).
   → Download with **native macOS SteamCMD** instead.

3. **Steam's "PLAY" button is a dead end.** It (a) tries to download the ~120 MB Steamworks redist,
   which stalls the same way, and (b) launches the game with **Steam's** environment, which has **no
   D3DMetal** → the "*A D3D11-compatible GPU (Feature Level 11.0) is required*" error.
   → **Never launch via Steam.** Launch via the Sikarugir wrapper.

4. **D3DMetal only engages through the Sikarugir launcher.** Setting `D3DMETAL=1` in the wrapper's
   `Info.plist` + opening the `.app` works. A **raw `wine game.exe`** — even with `CX_D3DMETALPATH`,
   `CX_APPLEGPTK_LIBD3DSHARED_PATH`, `DYLD_FALLBACK_LIBRARY_PATH`, etc. all set correctly — **falls back
   to WineD3D (DirectX→Vulkan) and fails the Feature-Level-11 check.** The launcher writes a
   bottle/registry flag that environment variables alone don't reproduce. **Always launch via `open`
   on the wrapper.**

5. **Don't mix Wine sync modes.** All Wine processes in one prefix must agree. The wrapper uses
   **esync**. If you set `WINEMSYNC=1` against an esync `wineserver`, you get
   `msync_init Failed to open msync shared memory file` and the game exits instantly.

6. **MW5 needs no Steam process.** It runs standalone via `steam_appid.txt` (containing `784080`, placed
   next to the game exe) + the cached license in the prefix. The ~2 GB Steam *client* baked into the
   prefix is unused dead weight, but **leave it** — it likely holds the ownership token, and removing it
   risks breaking offline launch for a 2 % size gain.

7. **`nohup wine …` can break under SIP.** macOS System Integrity Protection strips `DYLD_*` env vars
   when it `exec`s a protected binary like `nohup`/`/bin/sh`. Set `DYLD_*` *inside* the launched script
   (after `nohup`), or just launch via the wrapper (which handles it).

---

## Controllers

MW5 supports **XInput**, and Wine exposes any macOS-connected controller to the game as an Xbox/XInput
pad. Xbox, PS4 (DualShock 4), and PS5 (DualSense) controllers all work.

1. **Pair/connect the controller to macOS *before* launching** (System Settings → Bluetooth, or USB-C):
   - Xbox Wireless/Series/One: hold the pair button, pair in Bluetooth.
   - PS5 DualSense / PS4 DS4: hold **PS + Share/Create** to enter pairing, pair in Bluetooth.
   - 8BitDo etc.: put it in **X-input / Xbox mode**.
2. Launch the game (`open` the wrapper). Wine 10 presents it as an XInput controller.
3. In game: **Options → Controls** — it should be detected; tweak bindings there.

**Gotchas:**
- Connect **before** launch; mid-game hotplug may not register.
- DualSense/DS4 show up *as an Xbox controller* — that's normal and works (no DS4Windows needed on Mac).
- **Do not run Steam** — Steam Input would fight Wine's XInput. We don't use Steam, so this is moot.
- Wired Sony controller misbehaving? In the wrapper's Wine "Game Controllers" control panel
  (Sikarugir Creator → open the wrapper → Advanced → Config Utility → `control` → Game Controllers),
  toggle **Disable hidraw**.

---

## Performance tuning (MW5 Graphics settings, ranked by impact)

Two facts shape this: the game runs through **two translation layers** (Rosetta + D3DMetal), so
draw-call-heavy settings cost a bit more than on native PC — and a Mac's **unified memory** makes
texture settings nearly free.

| Setting | What it does | FPS impact | Recommendation |
|---|---|---|---|
| **Resolution Scale** | Internal render % (upscaled) | ⭐⭐⭐⭐⭐ biggest lever | **85** (FidelityFX hides the softness); 75–80 for max FPS |
| **Shadows Quality** | Shadow detail + distance | ⭐⭐⭐⭐ | Medium → **Low** if stuttering |
| **Effects Quality** | Explosions/weapons/smoke | ⭐⭐⭐⭐ in combat | **Medium** (Low if firefights chug) |
| **Post Processing** | Bloom, motion blur, AO | ⭐⭐⭐ | **Medium/Low** (Low feels crisper) |
| **View Distance** | LOD draw distance | ⭐⭐⭐ (draw-call heavy) | **Medium** |
| **Foliage** | Vegetation density | ⭐⭐ (map-dependent) | **Medium** |
| **Textures Quality** | Texture resolution | ⭐ FPS / heavy memory | **High** — ~free with ≥32 GB unified memory |
| **Anti-Aliasing Mode/Quality** | Edge smoothing | ⭐⭐ | TAA/TXAA Medium; FXAA for more FPS |
| **Anisotropy** | Sharpness at grazing angles | ⭐ ~free | **16X** |
| **FidelityFX Sharpening** | Sharpening pass | ⭐ cheap, helps | **On** (counters lower Resolution Scale) |

Biggest smoothness dials: **Resolution Scale, Shadows, Effects.** Free wins: **Textures High,
Anisotropy 16X.** A lot of first-session stutter is **shader compilation** and fades as you play; a
**VSync / frame cap** (DISPLAY tab) smooths pacing.

**FPS overlay:** set `METAL_HUD` to `1` in `Info.plist`
(`plutil -replace METAL_HUD -integer 1 .../MechWarrior5.app/Contents/Info.plist`), relaunch.

---

## Portability — move to another Mac (no Steam, no Homebrew there)

The wrapper `.app` is self-contained and relocatable. To move it:

```sh
# 1. Copy the ~98 GB bundle (external SSD is fastest; rsync preserves the bundle)
rsync -a --info=progress2 ~/Applications/Sikarugir/MechWarrior5.app /Volumes/YOUR_SSD/

# On the other Mac, three one-time commands:
softwareupdate --install-rosetta --agree-to-license          # Apple Silicon only
xattr -dr com.apple.quarantine "/path/to/MechWarrior5.app"   # clear "from another Mac" flag
open "/path/to/MechWarrior5.app"
```

The target Mac needs **only** Rosetta 2 + macOS 14–27 + ~100 GB. **No Steam, no Sikarugir Creator, no
Homebrew.** You can even keep the `.app` on an external SSD and run it from there on multiple Macs
(do the `xattr` + Rosetta steps once per machine). The included `setup-on-new-mac.sh` does all three.

---

## Doing this for ANOTHER Steam game

The recipe generalizes. Per game:
1. Find its **Steam AppID** (the number in its store URL, or on https://steamdb.info).
2. Download with SteamCMD: `+@sSteamCmdForcePlatformType windows +force_install_dir <dir> +login <user> +app_update <APPID> validate +quit`.
3. Graft into a wrapper's prefix (a fresh wrapper per game is cleanest), set `Info.plist` `Program Name and Path` to the game's `.exe`, `D3DMETAL=1`, and `Program Flags` (`-dx11` for most Unreal Engine titles).
4. `open` the wrapper; tune.

**Will it work? Check first:**
- ✅ **Single-player / no kernel anti-cheat** games are the sweet spot.
- ❌ **Kernel-level anti-cheat** (most competitive multiplayer: EAC/BattlEye in kernel mode) **won't run** on free Wine. (Paid CrossOver 26 added some EAC/BattlEye support; free wrappers haven't.)
- ⚠️ **Strict always-online / Steam DRM** games may need the Steam client *running* — then you'd download with SteamCMD but launch with the in-wrapper Steam open (its downloader stalls, but it can stay logged in for DRM).
- ⚠️ **DirectX version:** D3DMetal handles DX11/DX12. DX9/DX10-only or 32-bit games may need DXVK or WineD3D instead (Sikarugir has toggles).
- 📊 **Check compatibility** before investing 95 GB: [AppleGamingWiki](https://www.applegamingwiki.com),
  [CodeWeavers CrossOver DB](https://www.codeweavers.com/compatibility), and
  [ProtonDB](https://www.protondb.com) (Linux/Proton is a decent proxy for what'll work).

---

## Troubleshooting (symptom → cause → fix)

| Symptom | Cause | Fix |
|---|---|---|
| `steamwebhelper is not responding` (in-Wine Steam) | Wine too old for Chromium-126 | Use Wine 10 (Sikarugir), not GPTK's 7.7 |
| Download stuck at N %, 0 bps, "Got N sources" loop | In-Wine Steam downloader stalls | Download with native SteamCMD |
| "Downloads disabled" / Offline Mode on PLAY | Steam went offline + redist download blocked | Don't use PLAY; launch via the wrapper |
| **"A D3D11-compatible GPU (FL 11.0) is required"** | D3DMetal didn't engage (raw `wine`, or Steam-launched) | Launch via the wrapper with `D3DMETAL=1` |
| Game exits instantly, log: `msync_init Failed…` | `WINEMSYNC=1` vs an esync wineserver | Use esync only (`WINEMSYNC=0`) |
| Game exits, no UE4 log | usually the msync mismatch or wrong launch | launch via the wrapper |
| Controller not detected | connected after launch / Steam Input interfering | connect first; don't run Steam; toggle "Disable hidraw" for wired PS pads |
| Stutter, first session | shader compilation | plays out; then lower Shadows/Resolution Scale + cap FPS |

---

## Reference

- **MechWarrior 5: Mercenaries** — Steam AppID **784080**
- Wrapper: `~/Applications/Sikarugir/MechWarrior5.app`
- Helper scripts: `~/Games/MechWarrior5/` (`launch-steam.sh`, `play-mw5.sh`, `download-mw5.sh`, `setup-on-new-mac.sh`)
- Sikarugir: https://github.com/Sikarugir-App/Sikarugir · WINE for Mac: https://wineformac.org
- Communities to share/learn: [AppleGamingWiki](https://www.applegamingwiki.com),
  r/macgaming, r/Mechwarrior5, [WINE for Mac](https://wineformac.org)
