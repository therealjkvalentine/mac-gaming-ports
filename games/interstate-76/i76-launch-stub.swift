// Interstate '76 direct-launch stub - installed AS the wrapper .app's main executable.
//
// Why it exists: the stock Sikarugir launcher breaks the game's Glide renderer two ways -
// it hardcodes CX_FWD_COMPAT_GL_CTX=1 (a forward-compatible GL context, fatal to OpenGLide's
// legacy immediate-mode OpenGL: reproduced as a crash at i76+0x4507C), and its working
// directory hides OpenGLid.INI (Glide wrappers read config from the CWD; missing INI means
// fullscreen defaults -> black screen). This stub does the proven direct launch instead.
// It must be a Mach-O binary - macOS 26's LaunchServices refuses shell scripts as bundle
// executables (tested).
//
// Install (original launcher kept for reference):
//   swiftc -O -o /tmp/i76stub i76-launch-stub.swift
//   APP=~/Applications/Sikarugir/Interstate76.app
//   mv "$APP/Contents/MacOS/Sikarugir" "$APP/Contents/MacOS/Sikarugir.orig"   # once
//   cp /tmp/i76stub "$APP/Contents/MacOS/Sikarugir"
//   codesign --force -s - "$APP/Contents/MacOS/Sikarugir"
import Foundation
let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let app = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let A = app.path
let game = A + "/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
setenv("DYLD_FALLBACK_LIBRARY_PATH", A + "/Contents/Frameworks:" + A + "/Contents/SharedSupport/wine/lib", 1)
setenv("WINEPREFIX", A + "/Contents/SharedSupport/prefix", 1)
setenv("WINEESYNC", "1", 1); setenv("WINEMSYNC", "1", 1)
FileManager.default.changeCurrentDirectoryPath(game)
let wine = A + "/Contents/SharedSupport/wine/bin/wine"
execv(wine, [strdup(wine), strdup("i76.exe"), strdup("-glide"), nil])
perror("execv wine failed")
