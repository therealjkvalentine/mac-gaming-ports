# Mac Gaming Ports 🎮🍎

Recipes for running **Windows-only Steam games on Apple Silicon Macs** with **free, open-source
tooling** — **Sikarugir / Wine 10 + Apple D3DMetal**, no CrossOver license. Each game becomes a
**self-contained `.app`** that runs **without Steam** and copies between Macs.

> Built & verified on Apple **M5 Pro / macOS 26 (Tahoe)**, May 2026. Works on M1–M5, macOS 14–27.
> "Ports" loosely — these are Wine wrappers, not native recompiles, but they run great.

## 🎯 Games

| Game | Steam AppID | Status | Guide |
|---|---|---|---|
| **MechWarrior 5: Mercenaries** | `784080` | ✅ Playable — D3DMetal, controller, no Steam | [games/mechwarrior-5-mercenaries](games/mechwarrior-5-mercenaries/) |

*More to come. PRs welcome — see [Adding a game](#-add-a-game).*

## ⚙️ The method in one breath
Wrap the game in a **Sikarugir Wine-10 `.app`**, download it with **native macOS SteamCMD** (the
Steam client *inside* Wine stalls on downloads), and **launch through the Sikarugir launcher** so
**D3DMetal** (DirectX→Metal) engages. The full walkthrough and the seven gotchas that make every
obvious shortcut fail are in **[AGENTS.md](AGENTS.md)**.

## 🚀 Quick start
Each `games/<game>/` folder has a README with that game's exact launch command and tuned settings.
The finished `.app` then just runs:
```sh
open ~/Applications/Sikarugir/<Game>.app
```

## ➕ Add a game
See **[AGENTS.md → Adding a game](AGENTS.md#-adding-a-game)**. In short: confirm it has **no
kernel-level anti-cheat**, download it via SteamCMD, point a wrapper at its `.exe` with `D3DMETAL=1`,
document it in a new `games/<slug>/` folder, and add a row to the table above. Check compatibility
first on [AppleGamingWiki](https://www.applegamingwiki.com) / [ProtonDB](https://www.protondb.com).

## ✅ Requirements
Apple Silicon Mac · macOS 14–27 · Rosetta 2 · free space for the game. (Homebrew only to *build* a
wrapper; running a prebuilt `.app` needs nothing but Rosetta.)

## 🔧 Repo layout
```
AGENTS.md                     # the general method + gotchas + how to add a game
scripts/setup-on-new-mac.sh   # one-time setup for a prebuilt .app on a fresh Mac
games/<slug>/                 # one folder per game: README + play/launch/download scripts
```

## 🤝 Sharing & references
Compatibility + community: [AppleGamingWiki](https://www.applegamingwiki.com) ·
[ProtonDB](https://www.protondb.com) · [CodeWeavers DB](https://www.codeweavers.com/compatibility) ·
[WINE for Mac](https://wineformac.org) · r/macgaming.

## License
[MIT](LICENSE). Contains **no game files** — only setup recipes and scripts. Game names and Steam are
trademarks of their respective owners.
