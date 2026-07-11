#!/bin/sh
# Interstate '76 - wire up in-mission music via DxWnd's virtual CD audio.
#
# WHY: I76's mission soundtrack was originally CD redbook audio (the game plays
# "CD audio track N"). The GOG version ships those tracks as music/2.mp3 .. music/17.mp3
# plus an (empty) tracklen.nfo. Under Wine there's no real CD, so the music is silent.
# DxWnd's virtual CD audio (its bundled dxwplay.dll) emulates the CD - BUT it looks for
# files named Music\TrackNN.mp3 (zero-padded), not the GOG N.mp3 naming. This script
# creates the TrackNN.mp3 names (hard links, no extra disk) and clears the broken empty
# tracklen.nfo so dxwplay regenerates it. The VIRTUALCDAUDIO flag is set in the profile
# (interstate-76.dxw: flagm0 bit 0). MP3 decode rides the GStreamer env the launch stub
# already sets. (Documented fix; the AiO patch readme also recommends DxWnd virtual CD.)
set -e
GAME="$HOME/Applications/Sikarugir/Interstate 76 - Software (DxWnd).app/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
MUS="$GAME/music"
[ -d "$MUS" ] || { echo "music folder not found: $MUS"; exit 1; }
cd "$MUS"
for f in [0-9]*.mp3; do
  [ -e "$f" ] || continue
  n="${f%.mp3}"
  printf -v tn "Track%02d.mp3" "$n" 2>/dev/null || tn=$(printf "Track%02d.mp3" "$n")
  [ -f "$tn" ] || ln "$f" "$tn"
done
rm -f "$MUS/tracklen.nfo"   # empty file breaks dxwplay; let it regenerate
echo "Music wired: $(ls Track*.mp3 2>/dev/null | wc -l | tr -d ' ') CD tracks -> TrackNN.mp3"
echo "Ensure the DxWnd profile has VIRTUALCDAUDIO on (flagm0 bit 0) - it is in interstate-76.dxw."
