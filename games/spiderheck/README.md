# SpiderHeck - Apple Silicon

Status: Playable - D3DMetal, controller, 4-player couch co-op, **fully offline via Goldberg (no Steam)**.
Verified on Apple M5 Pro / macOS 26 (Tahoe), May 2026.
Steam AppID: 1329500. Engine: Unity 2020.3 (DX11). Anti-cheat: none. ProtonDB Platinum.

Shared stack: Sikarugir + Wine 10 + D3DMetal + native SteamCMD. The wrapper was cloned from the
MechWarrior 5 one (same engine; APFS copy-on-write is instant and near-free). Full method:
[../../AGENTS.md](../../AGENTS.md).

## Launch
```sh
open ~/Applications/Sikarugir/SpiderHeck.app
```
Fully offline, no Steam (see below). The older `play.sh` (start Steam, then the game) still works but is
no longer needed once Goldberg is in.

## Fully offline - via Goldberg
SpiderHeck used to **require** a logged-in Steam in the same Wine session: its load coroutines
(`Achievements.Setup`, `MultiplayerManager.PCBackendCheck`, `DLCManager.CheckDLC`) call Steamworks, and
if `SteamAPI_Init()` fails they throw - leaving the game stuck forever on "Loading..." (rendering and
audio are fine; only the platform layer is blocked).

Goldberg removes that dependency. We replaced `SpiderHeckApp_Data/Plugins/x86_64/steam_api64.dll` with
[gbe_fork](https://github.com/Detanup01/gbe_fork)'s plus a `steam_settings/` folder (appid 1329500, the
interface list, `unlock_all=1`, `offline=1`). The game now loads straight to a local lobby with **no
Steam** - confirmed by `Steamworks is not initialized` = 0 and `New Lobby state: local` in the Unity
log, and a `GSE Saves/` folder appearing. See
[AGENTS.md, "Going fully Steam-free"](../../AGENTS.md#going-fully-steam-free-goldberg-for-owned-games).
Reversible via `steam_api64.dll.orig-backup`.

## Co-op
- **Couch (best for a plane):** up to 4 local players, one screen. Pair Xbox / PS5 / PS4 pads via
  Bluetooth before launching; they enumerate as XInput. Press a button on each to join. No networking.
- **LAN:** the log shows SpiderHeck uses Steam P2P (`P2p (StartServer)`), so LAN co-op over Goldberg is
  plausible (set `offline=0` + networking on, a unique identity per machine - see AGENTS.md). It also
  uses EOS for Xbox crossplay, which Goldberg won't bridge; Steam-to-Steam LAN should work.

## Build specifics
- SteamCMD AppID 1329500. Install dir `SpiderHeck`. Exe `SpiderHeck\SpiderHeckApp.exe` (note:
  `SpiderHeckApp.exe`, not `SpiderHeck.exe`).
- Wrapper `Info.plist`: `Program Flags` empty (Unity picks its own renderer), `D3DMETAL`=1.

## Diagnose a stuck load
Unity log: `.../prefix/drive_c/users/<you>/AppData/LocalLow/Neverjam Studio/SpiderHeckApp/Player.log`.
`Steamworks is not initialized` > 0 means the Steam layer failed - with Goldberg it should be 0.
`Leaderboard ... InvalidUser` is harmless (online leaderboards don't auth offline; local play unaffected).
