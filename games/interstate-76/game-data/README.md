# game-data/ — bring your own (never committed)

This folder holds the copy-protected Interstate '76 game files. Like OpenRA, this repo ships
only recipes and configs — you supply the game data from a copy you own. Everything in this
folder except this README is gitignored.

Expected contents:

| File | What it is | Where you get it |
|---|---|---|
| `i76-stable-gog.zip` | Zipped portable GOG install of I76 Gold (`i76.exe` 2019-09-01, MD5 `60abf7bc699da72476128ddce991a3d1`, bundled OpenGLide). Config is file-based — a zip of the install folder is a working install. | Buy [Interstate '76 on GOG](https://www.gog.com/game/interstate_76), install (on any PC or via the offline installer), zip the game folder. |
| `I76_CD1.ISO` | Original CD image (~373 MB). Only needed for the 86Box emulation path — the GOG installer won't run inside Win95. | Rip your own CD. |

If you own the GOG copy you only need the zip (or just install fresh from the GOG offline
installer into the wrapper — same result).
