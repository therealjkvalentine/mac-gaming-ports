# MechWarrior 5: Mercenaries - Apple Silicon

Status: Playable - D3DMetal, full controller support, all DLC, **fully offline (no Steam)** via Goldberg,
plus cheat mods and LAN co-op prepped. Verified on Apple M5 Pro / macOS 26 (Tahoe), May 2026.
Steam AppID: 784080. Engine: Unreal Engine 4 (DX11/12). Anti-cheat: none (single-player).

Built on the shared stack (Sikarugir + Wine 10 + D3DMetal + native SteamCMD), plus the Goldberg
Steamworks emulator for offline DLC. Full method: [../../AGENTS.md](../../AGENTS.md).

## Launch
```sh
open ~/Applications/Sikarugir/MechWarrior5.app      # or: zsh play.sh
```
Fully offline, no Steam. First launch compiles shaders - a black/loading screen for 1-3 minutes is normal.

## DLC, fully offline - via Goldberg
The base game runs standalone, but DLC ownership is a Steamworks check. Two ways to satisfy it:
- **(superseded) Steam in the same session** - start the in-wrapper Windows Steam (msync) logged in,
  *then* `open` the wrapper so the launcher joins that session and the game reads entitlements live.
  Works, but means running Steam every launch, and the launcher must use msync to share the session.
- **(current) Goldberg** - replace `Engine/Binaries/ThirdParty/Steamworks/Steamv153/Win64/steam_api64.dll`
  with [gbe_fork](https://github.com/Detanup01/gbe_fork)'s, plus a `steam_settings/` folder
  (`steam_appid.txt`=784080, the interface list, `configs.app.ini` -> `unlock_all=1`, `configs.main.ini`
  -> `offline=1`). The game then reports all owned DLC with **no Steam at all**. See
  [AGENTS.md, "Going fully Steam-free"](../../AGENTS.md#going-fully-steam-free-goldberg-for-owned-games).
  Reversible via `steam_api64.dll.orig-backup`.

## Cheats (single-player)
In `.../MW5Mercs/Mods/`, enabled in `modlist.json`:
- **SimpleCheatMod** + **Mod Options** (Bobbert) - an in-game toggle menu: free refit, near-infinite
  ammo, weightless gear, cheap salvage, and **Early Intro Date (Units)**, which unlocks era-locked mechs
  (the Timber Wolf / Clan OmniMechs appear with this on - otherwise they are gated to the 3050+ era).
- **NoDamage** (Nexus 283) - full invulnerability. Old mod: bump its `mod.json` `gameVersion` to the
  game's (e.g. `1.13.387`) or the loader greys it out.
- Lesson learned: a version-mismatched mod the loader is *forced* to load can crash at startup
  (`EXCEPTION_ACCESS_VIOLATION`). The loader auto-enables any folder in `Mods/`, so disable a bad mod by
  **moving its folder out**, not just `bEnabled:false`. "Enable Infantry" (PGI_Infantry, v1.1) crashes
  on v1.13 - keep it out of `Mods/`.

## LAN co-op (offline, no internet)
MW5 has 4-player co-op. With Goldberg it can run over a LAN (one router, no internet) among owned copies:
each machine needs the same build + mods, Goldberg with a unique identity, the same subnet/port, and
networking enabled. MW5 joins by invite, so the client uses Goldberg's `lobby_connect` to join the
host's lobby. See [AGENTS.md, "LAN co-op"](../../AGENTS.md#lan-co-op-without-internet). It is the fiddly
path - test at home first; MW5's co-op netcode is host-authoritative and a little desync-y.

## Recommended settings (M-series, balanced)
Resolution Scale 85, Textures High, Anisotropy 16X, Shadows Medium, Effects Medium, Post Processing
Medium, View Distance Medium, Anti-Aliasing TAA/Medium, FidelityFX Sharpening On, plus VSync or a frame
cap. If combat stutters after shaders warm up: Shadows to Low, Resolution Scale to 78.
Full impact table: [../../AGENTS.md#performance-tuning](../../AGENTS.md#performance-tuning).

## Controller
Pair an Xbox / PS5 (DualSense) / PS4 pad via Bluetooth before launching; it shows up as an XInput
controller; enable it in Options -> Controls. Wired-PlayStation-pad fix:
[../../AGENTS.md#controllers](../../AGENTS.md#controllers).

## Known quirks
- The intro logo videos are loose `.bk2` files in `Content/Movies/` (legalsplash-pc, piranha-logo,
  intro_video). Renaming them to `.bak` skips the intros - but it does **not** cut load time (shader
  compile + level load dominate), so we left them stock.
- Do not use Steam's PLAY button (only relevant in the superseded Steam path) - it stalls on the
  Steamworks redist and launches without D3DMetal. Launch via the wrapper.
- FPS overlay: `plutil -replace METAL_HUD -integer 1 ~/Applications/Sikarugir/MechWarrior5.app/Contents/Info.plist`, then relaunch.
