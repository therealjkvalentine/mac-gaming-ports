# Need for Speed: Most Wanted (2012) - Apple Silicon

Status: Playable, but via **CrossOver** - NOT the free Sikarugir stack. Verified on Apple M5 Pro /
macOS 26 (Tahoe), May 2026.
Steam AppID: 1262560 (the 2012 Criterion game; owned on Steam). Engine: Criterion / DX11.
DRM: Steamworks + EA (Origin) - the EA app is required at every launch.

> This is the one title in this repo the free stack cannot run, and it is documented here precisely so
> that limit is on record. For the general free method, see [../../AGENTS.md](../../AGENTS.md). This
> entry is the CrossOver exception.

## Why not the free stack
NFS MW 2012's DRM checks for EA's launcher (the EA app) at launch. The EA app is a heavy Electron app
that runs under CrossOver but not under free Wine (Whisky's EA-app guide is archived/dead, and the
EA app's CEF UI does not come up on the free engines). The only way to run the game launcher-free is a
DRM crack, which this project does not do. So this title requires **CrossOver** (free 14-day trial, or
licensed).

## How it runs (CrossOver)
- Install CrossOver: `brew install --cask crossover` (runs on the free trial). v26.1 = Wine 11 + D3DMetal.
- One CrossOver bottle ("EA App") holds BOTH the **EA app** (installed + signed in) and the **Windows
  Steam client**, installed into the same bottle so NFS sees both halves of its DRM.
- Install NFS from the Steam library inside the bottle (game dir `Need for Speed(TM) Most Wanted`,
  exe `NFS13.exe`). First launch performs the one-time EA activation that links the Steam copy to the
  EA account.
- Launch via the bottle's Steam Play button.

## Gotchas
- **Native macOS Steam conflict (the big one):** the native Steam fights the bottle's Steam for the same
  network ports and stalls downloads/launches. It auto-respawns via the
  `~/Library/LaunchAgents/com.valvesoftware.steamclean.plist` LaunchAgent. **Quit native Steam (or
  disable its auto-start: native Steam > Settings > Interface > uncheck "Run Steam when my computer
  starts") before playing.** This same conflict likely caused the MechWarrior 5 in-Wine download stalls.
- **Performance:** drop Shadow + Effects detail first (heaviest). A 2012 game has plenty of headroom on
  M-series.
- **Overlay / audio fixes:** disable the EA in-game (Origin) overlay in the EA app's Settings >
  Application; turn off audio reverberation in the game's audio options.
- **Reducing overhead:** once the copy is linked to EA, it may be installable via the EA app alone
  (dropping the Steam client and the port-conflict), but the EA app itself is still required at launch.
  There is no fully launcher-free legitimate configuration.
