#!/bin/zsh
# Download SpiderHeck (Windows depot) via NATIVE macOS SteamCMD.
# Uses your Mac's real networking (reliable), not Wine's (which stalls).
#
# RUN THIS IN YOUR OWN TERMINAL (e.g. Ghostty), so you can type your password:
#
#     zsh ~/Games/SpiderHeck/download-spiderheck.sh YOUR_STEAM_LOGIN_NAME
#
# - Use your Steam *account/login* name (not the display name).
# - You'll be prompted for your password, then a Steam Guard code (phone app or email).
# - SpiderHeck is small (~1.5 GB), so this is quick. Safe to re-run (it resumes / validates).

USER_LOGIN="${1:?Usage: zsh download.sh <your_steam_login_name>}"
STEAMCMD="$HOME/Games/MechWarrior5/steamcmd/steamcmd.sh"   # reuse the existing SteamCMD
TARGET="$HOME/Games/SpiderHeck/spiderheck-windows"          # space-free path; moved into the wrapper afterward

mkdir -p "$TARGET"
echo "Downloading SpiderHeck (AppID 1329500, Windows depot) to:"
echo "  $TARGET"
echo "Account: $USER_LOGIN"
echo

# Order matters: force Windows platform, set install dir BEFORE login.
"$STEAMCMD" \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$TARGET" \
  +login "$USER_LOGIN" \
  +app_update 1329500 validate \
  +quit

echo
echo "=== SteamCMD finished. Move the files into the wrapper's steamapps/common/SpiderHeck, then add"
echo "    steam_appid.txt (containing 1329500) next to SpiderHeckApp.exe. ==="
