#!/bin/sh
# Interstate '76 - build & install all three launchers. Idempotent; run after any
# stub source change. Requires: Xcode CLT (swiftc), the Interstate76.app wrapper
# already set up (see README).
#
#   1. Interstate76.app          - THE game (DxWnd big-window mode, dxwnd.exe /R:1)
#   2. I76 Voodoo.app            - dgVoodoo Glide mode (bright 3dfx color, 2x res;
#                                  one-time pipeline break-in - see README)
#   3. I76 DxWnd Settings.app    - DxWnd GUI for tweaking the profile
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
SIK="$HOME/Applications/Sikarugir"
APP="$SIK/Interstate76.app"
[ -d "$APP" ] || { echo "wrapper not found: $APP"; exit 1; }
TMP="$(mktemp -d)"

# --- 1. main stub -> replaces the wrapper's executable (orig kept as Sikarugir.orig)
swiftc -O -o "$TMP/main-stub" "$HERE/i76-launch-stub.swift"
MACOS="$APP/Contents/MacOS"
[ -f "$MACOS/Sikarugir.orig" ] || cp "$MACOS/Sikarugir" "$MACOS/Sikarugir.orig"
cp "$TMP/main-stub" "$MACOS/Sikarugir"
codesign -f -s - "$MACOS/Sikarugir"   # sign stub alone; --deep chokes on symlinks

# --- 2+3. satellite apps: tiny bundles that point at the wrapper
ICON="$(ls "$APP/Contents/Resources"/*.icns 2>/dev/null | head -1)"
make_app() { # $1=dir-name $2=bundle-id $3=swift-src $4=display-name
    B="$SIK/$1.app/Contents"
    mkdir -p "$B/MacOS" "$B/Resources"
    swiftc -O -o "$B/MacOS/$1" "$HERE/$3"
    [ -n "$ICON" ] && cp "$ICON" "$B/Resources/app.icns"
    cat > "$B/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>$1</string>
    <key>CFBundleIdentifier</key><string>$2</string>
    <key>CFBundleName</key><string>$4</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>app</string>
    <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF
    codesign -f -s - "$B/MacOS/$1"
}
make_app "I76 Voodoo"         "com.jkv.i76.voodoo"   "i76-voodoo-stub.swift"   "I76 Voodoo"
make_app "I76 DxWnd Settings" "com.jkv.i76.settings" "i76-settings-stub.swift" "I76 DxWnd Settings"

rm -rf "$TMP"
echo "Installed:"
echo "  $APP                     (play - DxWnd big window)"
echo "  $SIK/I76 Voodoo.app          (play - dgVoodoo Glide, pretty mode)"
echo "  $SIK/I76 DxWnd Settings.app  (tweak DxWnd options)"
