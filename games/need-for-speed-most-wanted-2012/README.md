# Need for Speed: Most Wanted (2012) - Apple Silicon

Status: Playable on the **free Sikarugir stack** (Wine 10 + D3DMetal), no CrossOver. Verified on
Apple M5 Pro / macOS 26 (Tahoe), June 2026.
Steam AppID: 1262560 (the 2012 Criterion game; owned on Steam). Engine: Criterion / DX11.
DRM: Steamworks + EA (Origin AccessDRM). The EA servers are shut down, which - counterintuitively - is
what makes the free stack work (see below).

> Earlier in this repo's history this title was the "CrossOver exception." That turned out to be
> unnecessary. It runs on the same free wrapper as MW5 and SpiderHeck, with two cosmetic caveats. The
> CrossOver bottle was only ever needed for the **one-time EA activation**, not to play.

## How it runs (free stack)
- The wrapper is a Sikarugir/Wine 10 + D3DMetal `.app`, cloned from the SpiderHeck wrapper (same engine
  family) via APFS copy-on-write, then pointed at `NFS13.exe`. See [../../AGENTS.md](../../AGENTS.md).
- The game files (`Need for Speed(TM) Most Wanted`, exe `NFS13.exe`) were obtained from a one-time
  legitimate install of the owned Steam copy, then copied into the wrapper. No Steam client, no EA app,
  no Goldberg, no crack inside the finished wrapper - it is self-contained.
- Launch: `open ~/Applications/Sikarugir/NeedForSpeedMostWanted.app`.

## The two caveats (both cosmetic, neither blocks play)
1. **"You must be signed in to the EA servers" prompt at startup.** The EA Autolog servers are dead, so
   the game's AccessDRM online check times out and the game shows a one-time press-to-continue dialog,
   then plays fully offline. There is no known clean flag/registry key to suppress it (the only "fixes"
   online are crack exes, which this project does not use). One keypress per launch.
2. **~1.8-minute opening movie plays every boot.** It is `UI/MOVIES/1307304.VP6`. It is NOT save-gated
   (a completed save does not skip it) and the game hard-requires the file to exist - deleting it or
   swapping in a shorter clip causes a black-screen hang, because the player waits for that exact
   stream. ThirteenAG's `SkipIntro=1` (installed) does not catch this particular movie. Left in place.

## Why this works without CrossOver (the key insight)
NFS MW 2012's EA DRM is "AccessDRM": at launch it tries to validate a license against EA's servers. We
originally assumed that required the EA app (which only runs under CrossOver, not free Wine). But with
the servers permanently offline, the check fails *open* - it cannot reach a server to deny the license,
so after the timeout prompt it proceeds. The EA app was only ever needed for the **initial activation**
handshake; once that's irrelevant (dead servers), the free wrapper runs the game directly. This is the
opposite of the usual "always-online DRM bricks the game" outcome - here the shutdown is what frees it.

## Build specifics
- Wrapper `Info.plist`: `Program Name and Path` = `...\Need for Speed(TM) Most Wanted\NFS13.exe`,
  `D3DMETAL` = 1, `Program Flags` empty. Icon set from the game's own icon.
- ThirteenAG Widescreen Fix (`dinput8.dll` + `scripts/`) is installed, but with the aspect-ratio
  options **off by default** (`FixHUD`/`FixFOV`/`FMVWidescreenMode`/`AutoFit* = 0`) so the game keeps
  its stock presentation on a laptop screen. Wine DLL override `dinput8 = native,builtin` is set so the
  ASI loader loads. (The fix is kept mainly as the SkipIntro vehicle and for optional FOV later.)
- Save location: `~/Documents/Criterion Games/Need For Speed(TM) Most Wanted/` (CrossOver/Wine map the
  Windows Documents to the native `~/Documents`, so the wrapper and the Mac share one save folder).

## Performance
Drop Shadow + Effects detail first (heaviest). A 2012 game has plenty of headroom on M-series.

## Multiplayer note
NFS MW 2012's online (EA Autolog) is shut down with no LAN and no revival. nfsmwo.com restores
multiplayer for the **2005** Most Wanted (`speed.exe`), a different, older game - not this one.
