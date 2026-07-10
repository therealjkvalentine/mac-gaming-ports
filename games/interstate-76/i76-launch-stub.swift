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
// under LaunchServices.
//
// CLOSE-FOR-REAL: we must reap when the GAME exits, not when dxwnd.exe exits - the
// DxWnd host stays resident after the game dies, so waiting on it never returns and
// the HideDesktop black backdrop window lingers (the "black wine window" that needed
// force-quit). So: wait for i76.exe to appear (boot), wait for it to vanish (quit or
// window-X via DxWnd's Terminate-on-close), then wineserver -k + sweep every process
// still referencing this bundle (dxwnd host, backdrop owner, winedevice, explorer).
// Build:  swiftc -O -o /tmp/stub i76-launch-stub.swift
import Foundation

let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let A = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path

func setupEnv(_ A: String) {
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
}

func running(_ pattern: String) -> Bool {
    let t = Process()
    t.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    t.arguments = ["-f", pattern]
    t.standardOutput = FileHandle.nullDevice
    t.standardError = FileHandle.nullDevice
    guard (try? t.run()) != nil else { return false }
    t.waitUntilExit()
    return t.terminationStatus == 0
}

func reap(_ A: String) {
    let k = Process()
    k.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wineserver")
    k.arguments = ["-k"]
    try? k.run(); k.waitUntilExit()
    Thread.sleep(forTimeInterval: 1)
    // Sweep survivors that reference THIS bundle (never touches other prefixes/games).
    // BUT: if the user already relaunched (new i76/dxwnd session up), skip the sweep -
    // a stale sweep would murder the fresh session; its own stub will clean up.
    if running("i76\\.exe") || running("dxwnd\\.exe") { return }
    let s = Process()
    s.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
    s.arguments = ["-9", "-f", A + "/Contents/SharedSupport"]
    try? s.run(); s.waitUntilExit()
}

setupEnv(A)
let p = Process()
p.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wine")
p.arguments = ["C:\\dxwnd\\dxwnd.exe", "/R:1"]
p.currentDirectoryURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/prefix/drive_c/dxwnd")
try! p.run()

// Boot phase: give wine + DxWnd + the game up to 2 min to get i76.exe running.
var booted = false
for _ in 0..<120 {
    Thread.sleep(forTimeInterval: 1)
    if running("i76\\.exe") { booted = true; break }
    if !p.isRunning && !running("dxwnd\\.exe") { break }  // launch failed outright
}
// Play phase: wait until the game process is gone (menu EXIT, or window-X ->
// DxWnd Terminate-on-close kills it).
while booted && running("i76\\.exe") {
    Thread.sleep(forTimeInterval: 2)
}
reap(A)
