#!/bin/zsh
# Launch Steam (and MechWarrior 5) in the Sikarugir Wine-10 wrapper, with D3DMetal enabled.
# Run:  zsh ~/Games/MechWarrior5/launch-steam.sh
# Then click PLAY on MechWarrior 5 in Steam. The game inherits D3DMetal from this env.

W="$HOME/Applications/Sikarugir/MechWarrior5.app"
DM="$W/Contents/Frameworks/renderer/d3dmetal/external"   # D3DMetal.framework + libd3dshared.dylib

export WINEPREFIX="$W/Contents/SharedSupport/prefix"

# --- D3DMetal (CrossOver-style): DirectX 11/12 -> Metal, best perf on Apple Silicon ---
export CX_D3DMETALPATH="$DM"
export CX_APPLEGPTK_LIBD3DSHARED_PATH="$DM/libd3dshared.dylib"
export DYLD_FALLBACK_LIBRARY_PATH="$DM:$W/Contents/Frameworks:$W/Contents/SharedSupport/wine/lib:/usr/lib:/usr/local/lib"
export MTL_HUD_ENABLED="${MTL_HUD_ENABLED:-1}"   # on-screen Metal FPS overlay (proof of D3DMetal); set 0 to hide

# --- Wine perf/quiet ---
export WINEESYNC=1
export ROSETTA_ADVERTISE_AVX=1               # expose AVX to UE4 via Rosetta
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="     # skip Mono/Gecko prompts

WINE="$W/Contents/SharedSupport/wine/bin/wine"
cd "$WINEPREFIX/drive_c/Program Files (x86)/Steam" || { echo "Steam not found"; exit 1; }
exec "$WINE" steam.exe -cef-disable-gpu "$@"
