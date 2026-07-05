import Foundation
let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let app = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let A = app.path
let game = A + "/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
setenv("DYLD_FALLBACK_LIBRARY_PATH", A + "/Contents/Frameworks:" + A + "/Contents/SharedSupport/wine/lib", 1)
setenv("WINEPREFIX", A + "/Contents/SharedSupport/prefix", 1)
setenv("WINEESYNC", "1", 1); setenv("WINEMSYNC", "1", 1)
// kept for the parked hybrid (-glide): harmless for -gdi
setenv("DXVK_ASYNC", "1", 1)
setenv("MVK_CONFIG_SHOULD_MAXIMIZE_CONCURRENT_COMPILATION", "1", 1)
FileManager.default.changeCurrentDirectoryPath(game)
let wine = A + "/Contents/SharedSupport/wine/bin/wine"
execv(wine, [strdup(wine), strdup("i76.exe"), strdup("-gdi"), nil])
perror("execv wine failed")
