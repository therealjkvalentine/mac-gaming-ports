#!/bin/zsh
# Launch MechWarrior 5 — no Steam needed.
# Runs through the Sikarugir wrapper, which engages D3DMetal (a raw `wine` call does NOT —
# it falls back to WineD3D and fails MW5's D3D11 feature-level check).
#
# The wrapper is pre-configured (Info.plist): Program = the game exe, D3DMETAL=1, flags = -dx11.
# Toggle the on-screen FPS/Metal HUD by setting METAL_HUD 1/0 in:
#   ~/Applications/Sikarugir/MechWarrior5.app/Contents/Info.plist  (plutil -replace METAL_HUD -integer 0 ...)

exec open "$HOME/Applications/Sikarugir/MechWarrior5.app"
