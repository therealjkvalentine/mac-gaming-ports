# MechWarrior 5: Mercenaries — Apple Silicon

**Status:** ✅ **Playable** — D3DMetal, full controller support, runs with **no Steam**. Verified on
Apple M5 Pro / macOS 26 (Tahoe), May 2026.
**Steam AppID:** `784080` · **Engine:** Unreal Engine 4 (DX11/12) · **Anti-cheat:** none (single-player)

> For the general method this is built on, see **[../../AGENTS.md](../../AGENTS.md)**.

## ▶️ Launch
```sh
open ~/Applications/Sikarugir/MechWarrior5.app      # or: zsh play.sh
```
First launch compiles shaders — a black/loading screen for 1–3 minutes is normal. **No Steam needed.**

## 📁 Scripts here
| Script | Purpose |
|---|---|
| `play.sh` | Launch the game (opens the wrapper) |
| `launch-steam.sh` | Launch the in-wrapper Windows Steam (rarely needed) |
| `download.sh` | (Re)download / verify the game via native SteamCMD |

## 🔧 Build specifics (vs. the general method)
- **Download:** SteamCMD AppID **784080**, `+@sSteamCmdForcePlatformType windows`.
- **Install dir:** `MechWarrior 5 Mercenaries` · **Exe:** `MW5Mercs\Binaries\Win64\MechWarrior-Win64-Shipping.exe`
- **Wrapper `Info.plist`:** `Program Flags` = `-dx11`, `D3DMETAL` = `1`.

## 🎚️ Recommended settings (M-series, balanced)
Resolution Scale **85** · Textures **High** · Anisotropy **16X** · Shadows **Medium** · Effects
**Medium** · Post Processing **Medium** · View Distance **Medium** · Anti-Aliasing **TAA/Medium** ·
FidelityFX Sharpening **On** · VSync or a frame cap **On**.
If combat stutters after shaders warm up: Shadows → **Low**, Resolution Scale → **78**.
Full impact table + reasoning: [../../AGENTS.md#performance-tuning](../../AGENTS.md#performance-tuning).

## 🎮 Controller
Pair an Xbox / PS5 (DualSense) / PS4 pad via Bluetooth **before** launching → it shows up as an XInput
controller → enable in **Options → Controls**. MW5 plays great on a pad. (Wired PlayStation pad fix +
details: [../../AGENTS.md#controllers](../../AGENTS.md#controllers).)

## ⚠️ Known quirks
- **Don't use Steam's PLAY button** — it tries to download the Steamworks redist (stalls in Wine) and
  launches without D3DMetal (→ "D3D11 GPU required"). Always launch via the wrapper.
- **FPS overlay:** `plutil -replace METAL_HUD -integer 1 ~/Applications/Sikarugir/MechWarrior5.app/Contents/Info.plist`, then relaunch.
