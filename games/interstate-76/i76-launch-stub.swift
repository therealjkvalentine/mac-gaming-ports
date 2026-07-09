// Interstate '76 launch stub - installed AS the wrapper .app's main executable
// (Contents/MacOS/Sikarugir; original launcher kept as Sikarugir.orig).
//
// Double-click the .app -> straight into the game via `dxwnd.exe /R:1` (DxWnd wraps
// the software renderer into a big 4:3 window; our profile has Desktop coords +
// KeepAspectRatio + HideDesktop). /R:1 = run target #1 (1-based -> ini index 0).
//
// CRITICAL env we must set because we bypass the stock Sikarugir launcher:
//  - GStreamer plugin paths: Wine's winegstreamer decodes the game's in-mission MP3
//    music (music/10.mp3..) via these. WITHOUT them, MCI-MP3 open fails, the game
//    retries in a tight loop -> multi-second freezes -> stack overflow crash, AND no
//    in-mission music. (The stock launcher sets GST_PLUGIN_PATH; we must too.)
//  - DYLD includes GStreamer.framework libs so those plugins can be dlopen'd.
//  - WINEESYNC+WINEMSYNC: msync (esync-only pins every wine proc at 100% CPU on macOS).
//
// Launch wine as a CHILD Process, not execv - execv breaks winemac GUI activation
// under LaunchServices. Build:  swiftc -O -o /tmp/stub i76-launch-stub.swift
import Foundation
let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let A = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
let gv = A + "/Contents/Frameworks/GStreamer.framework/Versions/1.0"
setenv("DYLD_FALLBACK_LIBRARY_PATH",
       A + "/Contents/Frameworks:" + gv + "/lib:" + A + "/Contents/SharedSupport/wine/lib", 1)
setenv("WINEPREFIX", A + "/Contents/SharedSupport/prefix", 1)
setenv("WINEESYNC", "1", 1); setenv("WINEMSYNC", "1", 1)
// GStreamer: let winegstreamer find the bundled codecs (MP3 in-mission music)
setenv("GST_PLUGIN_PATH", gv + "/lib/gstreamer-1.0", 1)
setenv("GST_PLUGIN_SYSTEM_PATH_1_0", gv + "/lib/gstreamer-1.0", 1)
setenv("GST_PLUGIN_SCANNER_1_0", gv + "/libexec/gstreamer-1.0/gst-plugin-scanner", 1)
setenv("GST_REGISTRY_1_0", A + "/Contents/SharedSupport/prefix/gst-registry.bin", 1)
let p = Process()
p.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wine")
p.arguments = ["C:\\dxwnd\\dxwnd.exe", "/R:1"]
p.currentDirectoryURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/prefix/drive_c/dxwnd")
try! p.run()
p.waitUntilExit()
// Reap the whole Wine session so nothing lingers after the game quits (fixes the
// "doesn't close when I close it" bug: wineserver + winedevice + explorer + services
// are separate processes that outlive dxwnd/the game unless explicitly killed).
let kill = Process()
kill.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wineserver")
kill.arguments = ["-k"]
try? kill.run(); kill.waitUntilExit()
