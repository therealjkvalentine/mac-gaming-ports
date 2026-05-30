# MechWarrior 5 on Apple Silicon — no Steam 🦿

MechWarrior 5: Mercenaries running natively-ish on Apple Silicon Macs via **free, open-source Wine
(Sikarugir / Wine 10) + Apple D3DMetal** — no Steam running, no CrossOver license.

## ▶️ Play
```sh
open ~/Applications/Sikarugir/MechWarrior5.app
```
First launch compiles shaders, so a black/loading screen for 1–3 minutes is normal. No Steam needed.

## 💻 Move it to another Mac
1. Copy `MechWarrior5.app` (and this folder) to the other Mac or an external SSD.
2. On the other Mac, run **`setup-on-new-mac.sh`** (installs Rosetta 2, clears the quarantine flag, launches).
3. Needs only: Apple Silicon, macOS 14–27, ~100 GB free. **No Steam, no Homebrew.**

## 📁 What's here
| File | Purpose |
|---|---|
| `setup-on-new-mac.sh` | One-time setup on a fresh Mac (Rosetta + un-quarantine + launch) |
| `play-mw5.sh` | Launch the game (just `open`s the wrapper) |
| `launch-steam.sh` | Launch the in-wrapper Windows Steam (rarely needed) |
| `download-mw5.sh` | Re-download / verify the game via native SteamCMD |
| **`AGENTS.md`** | **The full guide** — build from scratch, every gotcha, controllers, tuning, other games |

## 📖 Full documentation
See **[AGENTS.md](AGENTS.md)** for the complete story: the toolchain, why each piece, the seven
gotchas that make the obvious approaches fail, controller setup, performance tuning, portability, and
how to repeat this for other Steam games.

*Built & verified on Apple M5 Pro / macOS 26 (Tahoe), May 2026.*
