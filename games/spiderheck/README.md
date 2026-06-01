# SpiderHeck - Apple Silicon

Status: Playable - D3DMetal, controller, local 4-player couch co-op. Verified on Apple M5 Pro /
macOS 26 (Tahoe), May 2026.
Steam AppID: 1329500. Engine: Unity 2020.3 (DX11). Anti-cheat: none.

Built on the shared stack: Sikarugir + Wine 10 + Apple D3DMetal + native SteamCMD. For the full method
and the reasoning behind each choice, see [../../AGENTS.md](../../AGENTS.md).

This was the easiest build in the repo: ProtonDB Platinum, a ~1.5 GB Unity game, no anti-cheat. The
wrapper was cloned from the MechWarrior 5 one (same engine) rather than built from scratch - see
"Cloning an existing wrapper" in AGENTS.md.

## Launch
```sh
zsh play.sh
```
Not a plain `open`: unlike MW5, SpiderHeck *requires* a logged-in Steam in the same Wine session (see
below). `play.sh` quits native Steam, starts the in-wrapper Steam, waits for it, then launches the game.
First run shows a Steam login window once - sign in and check "Remember my password".

## Scripts here
- `play.sh` - the launch (starts in-wrapper Steam, then the game)
- `steam.sh` - start only the in-wrapper Steam (for the one-time login)
- `download.sh` - download / verify the game via native SteamCMD

## Build specifics (vs. the general method)
- Download: SteamCMD AppID 1329500, `+@sSteamCmdForcePlatformType windows`. Install dir `SpiderHeck`.
- Exe: `SpiderHeck\SpiderHeckApp.exe` (note: `SpiderHeckApp.exe`, not `SpiderHeck.exe`).
- Wrapper `Info.plist`: `Program Flags` = empty (Unity picks its own renderer), `D3DMETAL` = `1`.
- `steam_appid.txt` containing `1329500` sits next to the exe (Valve's own SDK file for launching a
  build directly - it is not Goldberg and does not touch `steam_api64.dll`; the real Valve DLL is intact).

## The one gotcha: SpiderHeck needs Steam running
MW5 runs with no Steam at all. SpiderHeck does not: its load coroutines (`Achievements.Setup`,
`MultiplayerManager.PCBackendCheck`, `DLCManager.CheckDLC`) call into Steamworks, and if
`SteamAPI_Init()` fails they throw - leaving the game stuck forever on the "Loading..." screen
(rendering and audio are fine; only the platform layer is blocked). The fix is legitimate and matches
MW5's DLC method: run the real in-wrapper Steam, logged into the account that owns the game, in the same
Wine session. `play.sh` does this. The real `steam_api64.dll` is untouched and gets a real answer - no
DRM emulator, no DLL swap.

To diagnose a stuck load, read the Unity log inside the prefix:
`.../SpiderHeck.app/Contents/SharedSupport/prefix/drive_c/users/<you>/AppData/LocalLow/Neverjam Studio/SpiderHeckApp/Player.log`
- `Steamworks is not initialized` = Steam not logged in / not in the same session (run `steam.sh`, log in).

## Controller / couch co-op
Up to 4 local players. Pair Xbox / PS5 (DualSense) / PS4 pads via Bluetooth before launching; they enumerate
as XInput. The log line `OnPlayerJoined ... Control scheme: Keyboard and mouse` confirms input is wired.
Plug in each pad and press a button to join.

## Known quirks
- Native macOS Steam must be quit first (it fights the in-wrapper Steam for ports). `play.sh` does this.
- `Leaderboard ... InvalidUser` in the log: online global leaderboards don't authenticate in this setup.
  Harmless - local play and couch co-op are unaffected.
- A genuinely Steam-free option exists in theory: the developer sells a direct download on itch.io. If
  that build is current and standalone (not wired to Steamworks), it would run with no Steam client at
  all. Not verified here; the Steam build above is what is tested and working.
