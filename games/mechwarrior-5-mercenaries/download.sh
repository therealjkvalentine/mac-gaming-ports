#!/bin/zsh
# Download MechWarrior 5: Mercenaries (Windows depots) via NATIVE macOS SteamCMD.
# This bypasses Wine's network layer entirely (which was stalling), using your Mac's
# real networking — proven to reach Steam's CDN perfectly.
#
# RUN THIS IN YOUR OWN TERMINAL (e.g. Ghostty), so you can type your password:
#
#     zsh ~/Games/MechWarrior5/download-mw5.sh YOUR_STEAM_LOGIN_NAME
#
# - Use your Steam *account/login* name (not the display name).
# - You'll be prompted for your password, then a Steam Guard code (phone app or email).
# - Download is ~38 GB with live progress. Safe to re-run — it resumes where it left off.

USER_LOGIN="${1:?Usage: zsh download-mw5.sh <your_steam_login_name>}"
STEAMCMD="$HOME/Games/MechWarrior5/steamcmd/steamcmd.sh"
TARGET="$HOME/Games/MechWarrior5/mw5-windows"   # space-free path; moved into the wrapper afterward

mkdir -p "$TARGET"
echo "Downloading MechWarrior 5 (AppID 784080, Windows depots) to:"
echo "  $TARGET"
echo "Account: $USER_LOGIN"
echo

# Order matters: force_install_dir BEFORE login; force Windows platform first.
"$STEAMCMD" \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$TARGET" \
  +login "$USER_LOGIN" \
  +app_update 784080 validate \
  +quit

echo
echo "=== SteamCMD finished. Tell Claude it's done and it will move the files into the game wrapper. ==="
