#!/bin/sh
# Interstate '76 - launch directly (default: bright Glide mode).
#   ./play.sh          -> -glide  (bright 3dfx colors, 1280x960)
#   ./play.sh gdi      -> -gdi    (small 640x480 window, zero quirks)
#
# Why not `open Interstate76.app` for Glide: OpenGLide reads OpenGLid.INI from
# the process working directory (dgVoodoo does the same with its conf), and the
# Sikarugir launcher's CWD is not the game dir - the INI is missed, OpenGLide
# defaults to fullscreen and you get a black screen. cd-ing here first is the fix.
# (`open` works fine for -gdi, which reads no INI - the launcher app uses that.)
set -e
MODE="-glide"; [ "$1" = "gdi" ] && MODE="-gdi"
APP="$HOME/Applications/Sikarugir/Interstate76.app"
GAME="$APP/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
pkill -f i76.exe 2>/dev/null || true; sleep 1
export DYLD_FALLBACK_LIBRARY_PATH="$APP/Contents/Frameworks:$APP/Contents/SharedSupport/wine/lib"
export WINEPREFIX="$APP/Contents/SharedSupport/prefix" WINEESYNC=1 WINEMSYNC=1
cd "$GAME"
exec "$APP/Contents/SharedSupport/wine/bin/wine" i76.exe "$MODE"
