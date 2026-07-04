#!/bin/sh
# Interstate '76 - launch the BRIGHT dgVoodoo hybrid (-glide) correctly.
# dgVoodoo reads dgVoodoo.conf from the process CWD, and the Sikarugir launcher's
# CWD is not the game dir - launching the wrapper via `open` therefore breaks the
# hybrid (fullscreen black + "Failed to initialize 3D hardware acceleration").
# This script cd's into the game folder first, which is the whole trick.
# Expect ~2 min of slow shader warmup per launch (see README) - let it simmer.
# Optional: pass 3x (or 2x/unforced) to set the sim resolution before launching.
set -e
APP="$HOME/Applications/Sikarugir/Interstate76.app"
GAME="$APP/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
[ -n "$1" ] && sed -i '' -E "s/^(Resolution[[:space:]]*= ).*/\\1$1/" "$GAME/dgVoodoo.conf"
pkill -f i76.exe 2>/dev/null || true; sleep 1
export DYLD_FALLBACK_LIBRARY_PATH="$APP/Contents/Frameworks:$APP/Contents/SharedSupport/wine/lib"
export WINEPREFIX="$APP/Contents/SharedSupport/prefix" WINEESYNC=1 WINEMSYNC=1
cd "$GAME"
exec "$APP/Contents/SharedSupport/wine/bin/wine" i76.exe -glide
