#!/bin/sh
# Interstate '76 with a 3dfx-style gamma lift (default 1.3) held while the game runs.
# The -gdi software renderer lacks the Voodoo hardware gamma the game was tuned for,
# so it looks dark; this brightens the display while playing and restores it on exit.
# Display-wide (macOS gamma is per-display, not per-window) - blunt but effective.
# Usage: ./play-bright.sh [gamma]     e.g. ./play-bright.sh 1.25
set -e
GAMMA=${1:-1.3}
DIR=$(cd "$(dirname "$0")" && pwd)
TOOL="${TMPDIR:-/tmp}/i76gamma"
[ -x "$TOOL" ] || swiftc -O -o "$TOOL" "$DIR/i76gamma.swift"   # needs Xcode CLT once
open "$HOME/Applications/Sikarugir/Interstate76.app"
# wait for the game process, then hold gamma until it exits
for i in $(seq 1 60); do pgrep -f i76.exe >/dev/null && break; sleep 2; done
"$TOOL" "$GAMMA" &
GPID=$!
trap 'kill $GPID 2>/dev/null' EXIT INT TERM
while pgrep -f i76.exe >/dev/null; do sleep 5; done
