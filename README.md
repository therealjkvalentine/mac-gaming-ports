# Mac Gaming Ports

Recipes for running Windows-only Steam games on Apple Silicon Macs with free, open-source tooling.
Each game becomes a self-contained `.app` that runs without Steam and copies between Macs.

Built and verified on Apple M5 Pro / macOS 26 (Tahoe), May 2026. Works on M1-M5, macOS 14-27.
"Ports" loosely: these are Wine wrappers, not native recompiles, but they run well.

## Games

Working on the free stack (Sikarugir/Wine + D3DMetal, no Steam at runtime):

| Game | Steam AppID | Status | Guide |
|---|---|---|---|
| MechWarrior 5: Mercenaries | 784080 | Playable - D3DMetal, controller, no Steam | [games/mechwarrior-5-mercenaries](games/mechwarrior-5-mercenaries/) |

Working, but requires CrossOver (the EA-DRM exception the free stack can't run):

| Game | Steam AppID | Status | Guide |
|---|---|---|---|
| Need for Speed: Most Wanted (2012) | 1262560 | Playable via CrossOver + EA app; not free-stack | [games/need-for-speed-most-wanted-2012](games/need-for-speed-most-wanted-2012/) |

Candidates (want a portable Mac version; not built yet):

| Game | Likely outcome with this method | Notes |
|---|---|---|
| Bloodstained: Ritual of the Night | High | Unreal Engine 4 / DX11 / single-player - essentially identical to MW5 |
| BattleTech (HBS) | High | Unity / DX11 / single-player; the old native Mac build is broken on Apple Silicon, so the Wine route is the fix |
| SpiderHeck | Likely | Unity; check for a working native Mac build first - it may not need Wine at all |

## The stack we settled on, and why

- **Sikarugir** (free, open-source; the maintained successor to Kegworks/Wineskin) - produces a self-contained, relocatable `.app`.
- **Wine 10** (Sikarugir's engine) - Apple's Game Porting Toolkit ships Wine 7.7, which is too old for the current Steam client.
- **Apple D3DMetal** (DirectX-to-Metal, free, bundled in the engine) - best DX11/12 performance on Apple Silicon; the open-source WineD3D/Vulkan path failed the game's GPU feature-level check.
- **Native macOS SteamCMD** - downloads the game reliably; the Steam client running inside Wine stalls on downloads.
- **Rosetta 2** - translates the x86-64 game and Wine to ARM.

## What we learned

- The in-Wine Steam client is the problem child: its downloader stalls after about 2 GB, and its Play button launches the game without D3DMetal. Download with native SteamCMD; launch via the wrapper.
- D3DMetal only engages when launched through the Sikarugir launcher (an Info.plist flag) - not from a raw `wine` call, even with the right environment variables.
- The finished game needs no Steam running at all; it runs standalone.
- The game files are the only real bulk (about 95 GB for MW5); the wrapper itself is roughly 1 GB and fully portable.
- Full detail - every gotcha, controllers, performance tuning - is in [AGENTS.md](AGENTS.md).

## Quick start

Each `games/<game>/` folder has that game's exact launch command and tuned settings. A finished
wrapper just runs:

```sh
open ~/Applications/Sikarugir/<Game>.app
```

## Add a game

See [AGENTS.md, "Adding a game"](AGENTS.md#adding-a-game). In short: confirm it has no kernel-level
anti-cheat, download it with SteamCMD, point a wrapper at its `.exe` with `D3DMETAL=1`, document it
under `games/<slug>/`, and add a row above. Check compatibility first on
[AppleGamingWiki](https://www.applegamingwiki.com) or [ProtonDB](https://www.protondb.com).

## Requirements

Apple Silicon Mac, macOS 14-27, Rosetta 2, free space for the game. Homebrew only to build a wrapper;
running a prebuilt `.app` needs nothing but Rosetta.

## Repo layout

```
AGENTS.md                     the general method, gotchas, controllers, tuning, adding a game
scripts/setup-on-new-mac.sh   one-time setup for a prebuilt .app on a fresh Mac
games/<slug>/                 one folder per game: README plus play/launch/download scripts
```

## Sharing and references

[AppleGamingWiki](https://www.applegamingwiki.com), [ProtonDB](https://www.protondb.com),
[CodeWeavers compatibility database](https://www.codeweavers.com/compatibility),
[WINE for Mac](https://wineformac.org), r/macgaming.

## License

[MIT](LICENSE). Contains no game files - only setup recipes and scripts. Game names and Steam are
trademarks of their respective owners.
