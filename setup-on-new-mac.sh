#!/bin/zsh
# One-time setup to run MechWarrior5.app on a fresh Apple Silicon Mac.
# Put this script next to MechWarrior5.app (e.g. on your external SSD) and run:
#     zsh setup-on-new-mac.sh
# It installs Rosetta 2, clears the quarantine flag, and launches the game.

echo "🦿 MechWarrior 5 — new-Mac setup"

# Find the wrapper: next to this script, then the usual install locations.
HERE="${0:A:h}"
APP=""
for cand in "$HERE/MechWarrior5.app" "$HOME/Applications/Sikarugir/MechWarrior5.app" "/Applications/Sikarugir/MechWarrior5.app"; do
  if [ -d "$cand" ]; then APP="$cand"; break; fi
done
if [ -z "$APP" ]; then
  echo "❌ Couldn't find MechWarrior5.app next to this script or in ~/Applications/Sikarugir/."
  echo "   Move this script next to the .app (or copy the .app to ~/Applications/Sikarugir/) and re-run."
  exit 1
fi
echo "   Wrapper: $APP"
echo

# 1. Rosetta 2 (Apple Silicon needs it to run the x86 Wine). Harmless if already installed.
if /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo "1/3  Rosetta 2 already present ✓"
else
  echo "1/3  Installing Rosetta 2…"
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license || \
    echo "   (Rosetta install reported an issue — if the game launches anyway, ignore this.)"
fi

# 2. Clear the "downloaded from another Mac" quarantine so macOS will run it.
echo "2/3  Clearing quarantine flag…"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null && echo "   done ✓" || echo "   (nothing to clear)"

# 3. Launch.
echo "3/3  Launching MechWarrior 5… (first launch compiles shaders — black screen for 1–3 min is normal)"
open "$APP"

echo
echo "✅ All set. From now on, just run:  open \"$APP\""
