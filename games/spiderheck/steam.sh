#!/bin/zsh
# Start the in-wrapper Windows Steam with msync (to MATCH the SpiderHeck launcher's sync mode), so Steam
# and the game share one Wine session -> the game's real Steamworks layer (SteamAPI_Init) succeeds.
# Called by play.sh; can also be run alone for a one-time interactive Steam login.
W="$HOME/Applications/Sikarugir/SpiderHeck.app"
export WINEPREFIX="$W/Contents/SharedSupport/prefix"
export DYLD_FALLBACK_LIBRARY_PATH="$W/Contents/Frameworks:$W/Contents/SharedSupport/wine/lib:/usr/lib"
export WINEMSYNC=1
export WINEESYNC=1
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="
cd "$WINEPREFIX/drive_c/Program Files (x86)/Steam" || exit 1
exec "$W/Contents/SharedSupport/wine/bin/wine" steam.exe -cef-disable-gpu "$@"
