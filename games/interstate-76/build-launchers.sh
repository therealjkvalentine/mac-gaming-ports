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

# --- icon: real I76 box art, generated from the user's own GOG files (gfw_high.ico
# ships with the game; never committed to the repo - repo ships no game files)
GAME="$APP/Contents/SharedSupport/prefix/drive_c/GOG Games/Interstate 76"
ICNS="$TMP/i76.icns"
if [ -f "$GAME/gfw_high.ico" ]; then
    mkdir -p "$TMP/icon.iconset"
    sips -s format png "$GAME/gfw_high.ico" --out "$TMP/i76.png" >/dev/null 2>&1
    for s in 16 32 128 256 512; do
        sips -z $s $s "$TMP/i76.png" --out "$TMP/icon.iconset/icon_${s}x${s}.png" >/dev/null 2>&1
        sips -z $((s*2)) $((s*2)) "$TMP/i76.png" --out "$TMP/icon.iconset/icon_${s}x${s}@2x.png" >/dev/null 2>&1
    done
    iconutil -c icns "$TMP/icon.iconset" -o "$ICNS" 2>/dev/null || ICNS=""
else
    ICNS=""
fi
MAIN_ICON="$(defaults read "$APP/Contents/Info.plist" CFBundleIconFile 2>/dev/null || echo "")"
[ -n "$ICNS" ] && [ -n "$MAIN_ICON" ] && cp "$ICNS" "$APP/Contents/Resources/${MAIN_ICON%.icns}.icns"

# --- 2+3. satellite apps: tiny bundles that point at the wrapper
ICON="$ICNS"
[ -n "$ICON" ] || ICON="$(ls "$APP/Contents/Resources"/*.icns 2>/dev/null | head -1)"
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
