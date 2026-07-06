// Interstate '76 launch stub - installed AS the wrapper .app's main executable
// (Contents/MacOS/Sikarugir; original launcher kept as Sikarugir.orig).
//
// Opens DxWnd (GPLv3 DirectDraw wrapper) with our tuned "Interstate 76" profile preloaded.
// Double-click the "Interstate 76" row to play - the software renderer then runs in a big,
// scalable, title-barred window ("Terminate on window close" quits cleanly on window close).
//
// IMPORTANT: launch wine as a CHILD Process, not execv. Replacing the app's main executable
// via execv() breaks winemac GUI activation under LaunchServices - DxWnd's main window never
// paints (only a blank aux window). Spawning wine as a child keeps the .app activated and the
// GUI appears. (Verified 2026-07; see docs/RUNNING-I76-EVERYWHERE.md.)
//
// Headless `dxwnd.exe /R:1` works on Linux (Lutris) but not macOS: it minimizes to the system
// tray, which winemac lacks, so the game never surfaces. GUI + double-click is the macOS path.
// Why not the stock Sikarugir launcher: it hardcodes CX_FWD_COMPAT_GL_CTX=1 and a wrong CWD.
// Build:  swiftc -O -o /tmp/stub i76-launch-stub.swift
import Foundation
let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let A = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
setenv("DYLD_FALLBACK_LIBRARY_PATH", A + "/Contents/Frameworks:" + A + "/Contents/SharedSupport/wine/lib", 1)
setenv("WINEPREFIX", A + "/Contents/SharedSupport/prefix", 1)
setenv("WINEESYNC", "1", 1); setenv("WINEMSYNC", "1", 1)
let p = Process()
p.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wine")
p.arguments = ["C:\\dxwnd\\dxwnd.exe"]
p.currentDirectoryURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/prefix/drive_c/dxwnd")
try! p.run()
p.waitUntilExit()
