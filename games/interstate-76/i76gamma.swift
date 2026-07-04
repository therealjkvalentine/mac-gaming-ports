// i76gamma <gamma> — hold a display gamma lift while this process is alive.
// 1.0 = normal, 1.3 ≈ the 3dfx hardware gamma every Glide-era game was tuned for.
// CoreGraphics transfer settings auto-revert when the process exits, so this
// tool just sets the curve and sleeps; kill it (or Ctrl-C) to restore.
// Build: swiftc -O -o i76gamma i76gamma.swift   (used by play-bright.sh)
import CoreGraphics
import Foundation
let g = CommandLine.arguments.count > 1 ? (Float(CommandLine.arguments[1]) ?? 1.0) : 1.3
CGSetDisplayTransferByFormula(CGMainDisplayID(), 0, 1, 1/g, 0, 1, 1/g, 0, 1, 1/g)
signal(SIGTERM) { _ in CGDisplayRestoreColorSyncSettings(); exit(0) }
signal(SIGINT)  { _ in CGDisplayRestoreColorSyncSettings(); exit(0) }
RunLoop.main.run()
