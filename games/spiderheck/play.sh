#!/bin/zsh
# Launch SpiderHeck on Apple Silicon (Sikarugir + Wine 10 + Apple D3DMetal).
#
# Why this is not a plain `open`: unlike MechWarrior 5, SpiderHeck's loading coroutines
# (Achievements.Setup, MultiplayerManager.PCBackendCheck, DLCManager.CheckDLC) call into Steam. If
# SteamAPI_Init() fails, those throw and the "Loading..." screen never finishes. The game's real Valve
# steam_api64.dll is untouched - it just needs a logged-in Steam in the SAME Wine session. So we start
# the in-wrapper Windows Steam (your account) with msync FIRST (matching the launcher's sync mode), wait
# for it to come up, then open the wrapper. The launcher JOINS the running session and SteamAPI_Init()
# succeeds. No emulator, no DLL swap.
#
# First time only: a Steam login window appears - sign in once and check "Remember my password".

W="$HOME/Applications/Sikarugir/SpiderHeck.app"
WS="$W/Contents/SharedSupport/wine/bin/wineserver"
HERE="${0:A:h}"

# 1) Quit native macOS Steam - it fights the in-wrapper Steam for network ports and stalls it.
osascript -e 'quit app "Steam"' 2>/dev/null
pkill -f 'Steam.AppBundle' 2>/dev/null
sleep 2

# 2) Clean slate so esync/msync can never collide across leftover processes.
"$WS" -k 2>/dev/null
sleep 2
pkill -9 -f steam.exe 2>/dev/null
pkill -9 -f steamwebhelper 2>/dev/null
pkill -9 -f SpiderHeckApp 2>/dev/null
pkill -9 -f UnityCrashHandler 2>/dev/null
sleep 2

# 3) Start the in-wrapper Steam (msync), wait up to ~90s for its UI, then launch the game.
echo "Starting Steam (msync) - waiting for it to log in..."
nohup zsh "$HERE/steam.sh" > /tmp/spiderheck-steam.log 2>&1 &
disown
for i in $(seq 1 45); do
  sleep 2
  if [ "$(pgrep -f steamwebhelper.exe | wc -l | tr -d ' ')" -ge 3 ]; then
    echo "Steam is up (~$((i * 2))s). Launching SpiderHeck..."
    sleep 5
    open "$W"
    echo "Launched."
    exit 0
  fi
done
echo "Steam did not come up in ~90s; launching anyway (it may hang on Loading)."
open "$W"
