-- I76 Launcher: GUI mode chooser for Interstate '76 on the Mac.
-- Build into an app:  osacompile -o "$HOME/Applications/Sikarugir/I76 Launcher.app" I76-Launcher.applescript
-- Classic = -gdi (instant, dark-ish, 640x480). Hybrid = dgVoodoo bright Glide
-- (launched cd-ed into the game dir so dgVoodoo.conf is found; ~2 min shader warmup).
on run
	set appPath to (POSIX path of (path to home folder)) & "Applications/Sikarugir/Interstate76.app"
	set gameDir to appPath & "/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
	set choices to {"Classic  (instant, small window)", "Bright Hybrid 2x  (1280x960, ~2min warmup)", "Bright Hybrid 3x  (1920x1440, ~2min warmup)", "Quit running game"}
	set pick to choose from list choices with title "Interstate '76" with prompt "Pick a mode:" default items {item 1 of choices}
	if pick is false then return
	set pick to item 1 of pick
	if pick starts with "Quit" then
		do shell script "pkill -f i76.exe || true"
		return
	end if
	if pick starts with "Classic" then
		do shell script "pkill -f i76.exe 2>/dev/null || true; plutil -replace 'Program Flags' -string '-gdi' " & quoted form of (appPath & "/Contents/Info.plist") & "; open " & quoted form of appPath
	else
		set res to "2x"
		if pick contains "3x" then set res to "3x"
		-- env is exported inside sh (SIP strips DYLD_* only at sh launch, not for its children)
		do shell script "pkill -f i76.exe 2>/dev/null || true; sleep 1; " & ¬
			"/usr/bin/sed -i '' -E 's/^(Resolution[[:space:]]*= ).*/\\1" & res & "/' " & quoted form of (gameDir & "/dgVoodoo.conf") & "; " & ¬
			"export DYLD_FALLBACK_LIBRARY_PATH=" & quoted form of (appPath & "/Contents/Frameworks:" & appPath & "/Contents/SharedSupport/wine/lib") & "; " & ¬
			"export WINEPREFIX=" & quoted form of (appPath & "/Contents/SharedSupport/prefix") & "; export WINEESYNC=1 WINEMSYNC=1; " & ¬
			"cd " & quoted form of gameDir & "; " & ¬
			quoted form of (appPath & "/Contents/SharedSupport/wine/bin/wine") & " i76.exe -glide > /tmp/i76-hybrid.log 2>&1 &"
	end if
end run
