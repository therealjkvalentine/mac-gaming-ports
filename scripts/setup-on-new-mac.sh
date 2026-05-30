#!/bin/zsh
# Generic one-time setup to run a Sikarugir game wrapper on a fresh Apple Silicon Mac.
# Installs Rosetta 2, clears the quarantine flag, and launches the .app.
#
# Usage:
#   put this next to a *.app and run:   zsh setup-on-new-mac.sh
#   or pass the wrapper explicitly:     zsh setup-on-new-mac.sh "/path/to/Game.app"

echo "Mac Gaming Ports - new-Mac setup"

APP="$1"
if [ -z "$APP" ]; then
  HERE="${0:A:h}"
  # look next to this script, one level up, and the default install location
  APP="$(ls -d "$HERE"/*.app "$HERE"/../*.app "$HOME"/Applications/Sikarugir/*.app 2>/dev/null | head -1)"
fi
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "No .app found. Run:  zsh setup-on-new-mac.sh \"/path/to/Game.app\""
  exit 1
fi
echo "Wrapper: $APP"
echo

if /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo "1/3  Rosetta 2 already present."
else
  echo "1/3  Installing Rosetta 2..."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license || \
    echo "     (reported an issue - if the game launches anyway, ignore it)"
fi

echo "2/3  Clearing the 'downloaded from another Mac' quarantine flag..."
xattr -dr com.apple.quarantine "$APP" 2>/dev/null && echo "     done" || echo "     (nothing to clear)"

echo "3/3  Launching... (first launch compiles shaders - a black screen for 1-3 min is normal)"
open "$APP"

echo
echo "Done. From now on, just run:  open \"$APP\""
