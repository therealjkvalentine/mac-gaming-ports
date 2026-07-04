#!/bin/sh
# Interstate '76 - launch the finished wrapper.
# The wrapper's launcher sets WINEESYNC+WINEMSYNC (msync) and everything else;
# the required registry keys (virtual desktop, win98, WindowsFloatWhenInactive)
# live in the prefix. See README.md for the full recipe.
exec open "$HOME/Applications/Sikarugir/Interstate76.app"
