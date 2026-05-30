# Running Windows Steam games on Apple Silicon — the method

> The **general, reproducible recipe** for running Windows-only Steam games on Apple Silicon Macs with
> **free, open-source tooling** (Sikarugir / Wine 10 + Apple D3DMetal) — no CrossOver license. The
> result is a **self-contained `.app`** that runs **without Steam** and copies between Macs.
>
> This file is the method. **Per-game specifics** (AppID, exe path, settings, quirks) live in
> [`games/<slug>/`](games/). Worked example: **[MechWarrior 5: Mercenaries](games/mechwarrior-5-mercenaries/)**.
>
> Written so a human *or* a coding agent can reproduce/repair it. **Read "The gotchas" before changing
> anything** — most obvious paths fail. Verified on Apple **M5 Pro / macOS 26 (Tahoe)**, May 2026.

---

## The stack (and why each piece)

| Layer | Choice | Why not the obvious thing |
|---|---|---|
| **Wrapper** | **Sikarugir** (free/OSS; successor to Kegworks → Wineskin) | Produces a self-contained, relocatable `.app`. Actively maintained for Apple Silicon + Tahoe. |
| **Wine** | **Wine 10** (Sikarugir engine `WS12WineSikarugir10.0`) | Apple's Game Porting Toolkit ships **Wine 7.7 (2022)** — too old; the current Steam client's Chromium-126 UI crash-loops on it. |
| **Graphics** | **D3DMetal** (Apple's DirectX→Metal, free, bundled in the Sikarugir engine) | Best DX11/12 perf on Apple Silicon. The OSS path (WineD3D→Vulkan→MoltenVK) often **fails a game's Feature-Level-11 check**. |
| **Download** | **native macOS SteamCMD** | The Steam client *running inside Wine* stalls on downloads (CDN connections drop after ~2 GB). Native SteamCMD uses the Mac's real networking. |
| **Translation** | **Rosetta 2** | Games + Wine are x86-64. Apple has committed to keeping Rosetta for games through macOS 28+. |

## Requirements
- Apple Silicon Mac (M1–M5), **macOS 14–27**
- **Rosetta 2**: `softwareupdate --install-rosetta --agree-to-license`
- **Homebrew** (only to build a wrapper): https://brew.sh
- Free space for the game + a Steam account that owns it (used once, by SteamCMD)

---

## The universal workflow

> Concrete values below use **MechWarrior 5** (AppID `784080`) as the example. Swap in your game's
> AppID and exe path. Find AppIDs on the Steam store URL or https://steamdb.info.

### 1. Install Sikarugir + Rosetta (once)
```sh
softwareupdate --install-rosetta --agree-to-license
brew install --cask Sikarugir-App/sikarugir/sikarugir
xattr -dr com.apple.quarantine "/Applications/Sikarugir Creator.app"
```

### 2. Build a Wine-10 wrapper
Open **Sikarugir Creator** → **Download Template** → keep the auto-selected **`WS12WineSikarugir10.0`**
engine (Wine 10 — do *not* pick an older one) → **Create**, name it `<Game>`, save (default
`~/Applications/Sikarugir/`). Result: a self-contained `~/Applications/Sikarugir/<Game>.app` with
`Contents/SharedSupport/wine/` (engine), `Contents/SharedSupport/prefix/` (the C: drive),
`Contents/Frameworks/renderer/d3dmetal/` (D3DMetal), and `Contents/Info.plist` (launch config).

### 3. Download the game with native SteamCMD (NOT the in-Wine Steam)
```sh
mkdir -p ~/SteamCMD && cd ~/SteamCMD
curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz | tar xzf -
./steamcmd.sh +quit   # self-update
# force_install_dir MUST come before login. Prompts for password + Steam Guard.
./steamcmd.sh +@sSteamCmdForcePlatformType windows \
  +force_install_dir ~/SteamCMD/dl/<Game> \
  +login YOUR_STEAM_LOGIN +app_update 784080 validate +quit
```

### 4. Graft the game into the wrapper
```sh
PFX=~/Applications/Sikarugir/<Game>.app/Contents/SharedSupport/prefix
DEST="$PFX/drive_c/Program Files (x86)/Steam/steamapps/common/<InstallDir>"
rm -rf "$DEST"; mv ~/SteamCMD/dl/<Game> "$DEST"     # instant on the same volume
rm -rf "$DEST/steamapps"                             # SteamCMD's own metadata
```

### 5. Point the wrapper at the game + enable D3DMetal
```sh
APP=~/Applications/Sikarugir/<Game>.app
plutil -replace "Program Name and Path" -string 'C:\...\Binaries\Win64\<Game>-Win64-Shipping.exe' "$APP/Contents/Info.plist"
plutil -replace "Program Flags" -string '-dx11' "$APP/Contents/Info.plist"   # most Unreal Engine titles
plutil -replace "D3DMETAL"  -integer 1 "$APP/Contents/Info.plist"            # << critical (gotcha #4)
plutil -replace "METAL_HUD" -integer 0 "$APP/Contents/Info.plist"            # 1 = FPS overlay
```

### 6. Launch
```sh
open ~/Applications/Sikarugir/<Game>.app
```

---

## The gotchas (READ THIS — the obvious paths all fail)

1. **GPTK's Wine 7.7 is too old.** The current Steam client's `steamwebhelper` (Chromium 126)
   crash-loops on it. → Use **Sikarugir's Wine 10**.
2. **The in-Wine Steam downloader stalls** (connects, pulls ~2 GB, then all CDN connections drop and
   it loops). The Mac's own networking is fine. → Download with **native macOS SteamCMD**.
3. **Steam's "PLAY" button is a dead end** — it tries to download dependencies (which stall) and
   launches the game with **no D3DMetal** (→ "*D3D11-compatible GPU (Feature Level 11.0) required*").
   → **Never launch via Steam.** Launch via the wrapper.
4. **D3DMetal only engages through the Sikarugir launcher.** `D3DMETAL=1` in `Info.plist` + `open`-ing
   the `.app` works. A **raw `wine game.exe`** — even with `CX_D3DMETALPATH`,
   `CX_APPLEGPTK_LIBD3DSHARED_PATH`, `DYLD_FALLBACK_LIBRARY_PATH` all set — **falls back to WineD3D
   (DirectX→Vulkan) and fails the Feature-Level-11 check.** The launcher writes a bottle/registry flag
   that env vars alone don't reproduce. **Always launch via `open`.**
5. **Don't mix Wine sync modes.** All Wine processes in one prefix must agree. The wrapper uses
   **esync**; setting `WINEMSYNC=1` against an esync `wineserver` gives `msync_init Failed…` and the
   game exits instantly.
6. **Many single-player games need no Steam process** — they run standalone via a `steam_appid.txt`
   (containing the AppID, next to the exe) + the cached license in the prefix. Leave the prefix's Steam
   client in place; it's unused but may hold the ownership token.
7. **`nohup wine …` can break under SIP.** macOS strips `DYLD_*` env vars when it `exec`s a protected
   binary like `nohup`/`/bin/sh`. Set `DYLD_*` *inside* the launched script, or just launch via the
   wrapper (which handles it).

---

## Controllers

Games that support **XInput** work: Wine presents any macOS-connected controller (Xbox, PS4/DS4,
PS5/DualSense) to the game as an Xbox/XInput pad.

1. **Pair/connect the controller to macOS *before* launching** (System Settings → Bluetooth, or USB).
   - Xbox: hold pair button. PS5/PS4: hold **PS + Share/Create**. 8BitDo: use **X-input mode**.
2. Launch the game; it appears as an XInput controller. Enable/bind in the game's controls menu.

**Gotchas:** connect *before* launch (hotplug may not register) · DualSense/DS4 show up *as Xbox*
(normal) · **don't run Steam** (Steam Input would fight Wine's XInput) · wired Sony pad acting up →
open the wrapper's Wine "Game Controllers" control panel and toggle **Disable hidraw**.

---

## Performance tuning

Two facts: games run through **two translation layers** (Rosetta + D3DMetal), so draw-call-heavy
settings cost a bit more than native — and a Mac's **unified memory** makes texture settings nearly
free. Biggest smoothness dials: **Resolution Scale, Shadows, Effects.** Free wins: **Textures High,
Anisotropy 16X.** First-session stutter is usually **shader compilation** and fades; a **VSync / frame
cap** smooths pacing. FPS overlay: set `METAL_HUD` to `1` in the wrapper's `Info.plist`.

Example (MechWarrior 5, UE4, M-series balanced): Resolution Scale **85** · Textures **High** ·
Anisotropy **16X** · Shadows **Medium** · Effects **Medium** · Post **Medium** · AA **TAA/Medium** ·
FidelityFX Sharpening **On**. Per-game tables live in each `games/<slug>/README.md`.

---

## Portability — move a finished `.app` to another Mac

The wrapper `.app` is self-contained and relocatable:
```sh
rsync -a --info=progress2 ~/Applications/Sikarugir/<Game>.app /Volumes/YOUR_SSD/   # external SSD = fastest
# On the other Mac:
softwareupdate --install-rosetta --agree-to-license          # Apple Silicon only
xattr -dr com.apple.quarantine "/path/to/<Game>.app"         # clear "from another Mac" flag
open "/path/to/<Game>.app"
```
The target Mac needs **only** Rosetta 2 + macOS 14–27 + free space. No Steam, no Homebrew, no
Sikarugir Creator. `scripts/setup-on-new-mac.sh` does all three steps. You can even run the `.app`
straight off an external SSD on multiple Macs.

---

## ➕ Adding a game

1. **Check compatibility first** (before downloading tens of GB):
   - ✅ **Single-player / no kernel anti-cheat** — the sweet spot.
   - ❌ **Kernel-level anti-cheat** (EAC/BattlEye in kernel mode — most competitive multiplayer) **won't
     run** on free Wine.
   - ⚠️ **Strict always-online / Steam DRM** may need the Steam client *running* (download via SteamCMD,
     then keep the in-wrapper Steam logged in for DRM).
   - ⚠️ **DirectX version:** D3DMetal handles DX11/12; DX9/DX10-only or 32-bit titles may need DXVK or
     WineD3D (Sikarugir has toggles).
   - 📊 Look it up: [AppleGamingWiki](https://www.applegamingwiki.com),
     [CrossOver DB](https://www.codeweavers.com/compatibility), [ProtonDB](https://www.protondb.com).
2. **Build + verify** with the universal workflow above.
3. **Document it:** add `games/<slug>/` with a `README.md` (status, AppID, launch command, tuned
   settings, controller notes, quirks) and `play.sh` / `download.sh` / `launch-steam.sh`.
4. **Index it:** add a row to the table in the top-level [README](README.md).
5. Open a PR.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `steamwebhelper is not responding` | Wine too old for Chromium-126 | Use Sikarugir's Wine 10 |
| Download stuck, 0 bps, "Got N sources" loop | in-Wine Steam downloader stalls | Use native SteamCMD |
| "Downloads disabled" / Offline Mode on PLAY | Steam offline + dependency download blocked | Don't use PLAY; launch via the wrapper |
| **"D3D11-compatible GPU (FL 11.0) required"** | D3DMetal didn't engage (raw `wine` or Steam-launched) | Launch via the wrapper with `D3DMETAL=1` |
| Game exits instantly, `msync_init Failed…` | `WINEMSYNC=1` vs esync wineserver | Use esync only |
| Controller not detected | connected after launch / Steam Input interfering | connect first; don't run Steam; toggle "Disable hidraw" for wired PS pads |
| Stutter, first session | shader compilation | plays out; then lower Shadows / Resolution Scale + cap FPS |

---

## Reference
- Sikarugir: https://github.com/Sikarugir-App/Sikarugir · WINE for Mac: https://wineformac.org
- Compatibility: [AppleGamingWiki](https://www.applegamingwiki.com) · [ProtonDB](https://www.protondb.com) · [CrossOver DB](https://www.codeweavers.com/compatibility)
- Communities: r/macgaming, and the game's own subreddit
