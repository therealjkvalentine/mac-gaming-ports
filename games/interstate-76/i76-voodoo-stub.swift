// Interstate '76 "Voodoo" launch stub - the dgVoodoo Glide mode (I76 Voodoo.app).
//
// Launches the game inside a COMMAND-LINE Wine virtual desktop:
//   wine explorer /desktop=I76Voodoo,1280x960 i76.exe -glide
// Why: with -glide the game's 2D shell (menus/cutscenes) runs DirectDraw exclusive-
// fullscreen -> a borderless whole-screen window that Wine hard-minimizes on every
// focus loss. The virtual desktop contains it in a real, movable, title-barred
// 1280x960 window instead - and 1280x960 exactly matches dgVoodoo's Resolution=2x
// sim output, so the 3D fills the same window. Using /desktop on the command line
// (not registry AppDefaults) keeps the DxWnd default mode desktop-free.
// Belt+braces: HKCU\...\AppDefaults\i76.exe\Mac Driver\WindowsFloatWhenInactive=all
// (set by setup-voodoo.sh) so the window floats rather than vanishes when unfocused.
//
// Render chain: i76.exe -glide -> dgVoodoo 2.78.2 Glide2x.dll (game dir) ->
// D3D11 FL10.1 -> DXVK (engine i386-windows) -> Vulkan -> MoltenVK -> Metal.
// Bright 3dfx color, 2x internal res, filtered textures - the pretty mode.
//
// TRADEOFF vs the DxWnd default: first-seen effects compile GPU pipelines
// (SPIRV->MSL) - a one-time "break-in". Mitigations wired here:
//   - dxvk.conf enableAsync: compiles on background threads, no render-thread stall.
//   - MVK_CONFIG_SHOULD_MAXIMIZE_CONCURRENT_COMPILATION: MoltenVK parallelizes.
//   - DXVK state cache (i76.dxvk-cache next to the exe) grows as you play and is
//     precompiled during the boot/menu minute of every later launch - hitches only
//     happen the FIRST time content is seen. Play a mission once; later runs warm.
//
// CWD must be the game dir: dgVoodoo.conf discovery is CWD-relative, and the DXVK
// state cache lands next to the exe. Same GStreamer/msync env as the main stub.
// Reap on GAME exit (poll i76.exe - the explorer desktop process outlives it).
// Build:  swiftc -O -o /tmp/voodoo i76-voodoo-stub.swift
import Foundation

// Satellite app: the wrapper bundle lives at a fixed place, not inside us.
let A = FileManager.default.homeDirectoryForCurrentUser.path
        + "/Applications/Sikarugir/Interstate76.app"
let gv = A + "/Contents/Frameworks/GStreamer.framework/Versions/1.0"
setenv("DYLD_FALLBACK_LIBRARY_PATH",
       A + "/Contents/Frameworks:" + gv + "/lib:" + A + "/Contents/SharedSupport/wine/lib", 1)
setenv("WINEPREFIX", A + "/Contents/SharedSupport/prefix", 1)
setenv("WINEESYNC", "1", 1); setenv("WINEMSYNC", "1", 1)
setenv("GST_PLUGIN_PATH", gv + "/lib/gstreamer-1.0", 1)
setenv("GST_PLUGIN_SYSTEM_PATH_1_0", gv + "/lib/gstreamer-1.0", 1)
setenv("GST_PLUGIN_SCANNER_1_0", gv + "/libexec/gstreamer-1.0/gst-plugin-scanner", 1)
setenv("GST_REGISTRY_1_0", A + "/Contents/SharedSupport/prefix/gst-registry.bin", 1)
// Pipeline-compile mitigations (see header)
setenv("MVK_CONFIG_SHOULD_MAXIMIZE_CONCURRENT_COMPILATION", "1", 1)
setenv("DXVK_STATE_CACHE", "1", 1)

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

let p = Process()
p.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wine")
p.arguments = ["explorer", "/desktop=I76Voodoo,1280x960",
               "C:\\GOG Games\\Interstate 76\\i76.exe", "-glide"]
p.currentDirectoryURL = URL(fileURLWithPath:
    A + "/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76")
try! p.run()

// Boot: give the game up to 2 min to appear; then wait for it to exit.
var booted = false
for _ in 0..<120 {
    Thread.sleep(forTimeInterval: 1)
    if running("i76\\.exe") { booted = true; break }
    if !p.isRunning { break }  // launch failed outright
}
while booted && running("i76\\.exe") {
    Thread.sleep(forTimeInterval: 2)
}
// Reap the wine session + sweep anything still referencing this bundle
// (explorer desktop, winedevice, ...). Skip the sweep if the user already
// relaunched - a stale sweep would murder the fresh session.
let k = Process()
k.executableURL = URL(fileURLWithPath: A + "/Contents/SharedSupport/wine/bin/wineserver")
k.arguments = ["-k"]
try? k.run(); k.waitUntilExit()
Thread.sleep(forTimeInterval: 1)
if !running("i76\\.exe") && !running("dxwnd\\.exe") {
    let s = Process()
    s.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
    s.arguments = ["-9", "-f", A + "/Contents/SharedSupport"]
    try? s.run(); s.waitUntilExit()
}
