-- I76 Launcher: GUI mode chooser for Interstate '76 on the Mac.
-- Build into an app:  osacompile -o "$HOME/Applications/Sikarugir/I76 Launcher.app" I76-Launcher.applescript
-- Glide  = bright 3dfx-gamma hardware path (OpenGLide -> OpenGL), 1280x960 window, instant.
--          Quirk: alt-tabbing away minimizes the window; it auto-restores on refocus.
-- Classic = -gdi software renderer, 640x480, darker, zero window quirks.
on run
	set appPath to (POSIX path of (path to home folder)) & "Applications/Sikarugir/Interstate76.app"
	set choices to {"Glide  (bright, 1280x960)", "Classic  (small window, zero quirks)", "Quit running game"}
	set pick to choose from list choices with title "Interstate '76" with prompt "Pick a mode:" default items {item 1 of choices}
	if pick is false then return
	set pick to item 1 of pick
	if pick starts with "Quit" then
		do shell script "pkill -f i76.exe || true"
		return
	end if
	set gameDir to appPath & "/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
	if pick starts with "Classic" then
		-- -gdi reads no INI; the wrapper launcher is fine for it
		do shell script "pkill -f i76.exe 2>/dev/null || true; plutil -replace 'Program Flags' -string '-gdi' " & quoted form of (appPath & "/Contents/Info.plist") & "; open " & quoted form of appPath
	else
		-- Glide MUST start with CWD = game dir (OpenGLide reads OpenGLid.INI from the CWD;
		-- missed INI -> fullscreen black). Direct wine launch; env exported inside sh.
		do shell script "pkill -f i76.exe 2>/dev/null || true; sleep 1; " & ¬
			"export DYLD_FALLBACK_LIBRARY_PATH=" & quoted form of (appPath & "/Contents/Frameworks:" & appPath & "/Contents/SharedSupport/wine/lib") & "; " & ¬
			"export WINEPREFIX=" & quoted form of (appPath & "/Contents/SharedSupport/prefix") & "; export WINEESYNC=1 WINEMSYNC=1; " & ¬
			"cd " & quoted form of gameDir & "; " & ¬
			quoted form of (appPath & "/Contents/SharedSupport/wine/bin/wine") & " i76.exe -glide > /tmp/i76-glide.log 2>&1 &"
	end if
end run
