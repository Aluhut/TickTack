#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
APP="$BUILD_DIR/TickTack.app"
mkdir -p "$BUILD_DIR/ModuleCache" "$APP/Contents/MacOS" "$APP/Contents/Resources"
ARCH="${ARCH:-$(uname -m)}"
VERSION="${VERSION:-0.9.0}"
/usr/bin/xcrun swiftc -O -parse-as-library \
    -target "$ARCH-apple-macos14.0" \
    -module-cache-path "$BUILD_DIR/ModuleCache" \
    -debug-prefix-map "$PROJECT_DIR=/TickTack" \
    Sources/TickTack/*.swift -framework SwiftUI -framework AppKit \
    -o "$APP/Contents/MacOS/TickTack"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp LICENSE "$APP/Contents/Resources/LICENSE"
cp THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/THIRD_PARTY_NOTICES.md"
/usr/bin/plutil -create xml1 "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Clear dict' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string TickTack' -c 'Add :CFBundleIdentifier string app.ticktack.desktop' -c 'Add :CFBundleName string TickTack' -c 'Add :CFBundleDisplayName string TickTack' -c 'Add :CFBundlePackageType string APPL' -c 'Add :CFBundleIconFile string AppIcon.icns' -c "Add :CFBundleShortVersionString string $VERSION" -c "Add :CFBundleVersion string $VERSION" -c 'Add :LSMinimumSystemVersion string 14.0' -c 'Add :NSHighResolutionCapable bool true' -c 'Add :CFBundleDevelopmentRegion string en' -c 'Add :CFBundleLocalizations array' -c 'Add :CFBundleLocalizations:0 string en' -c 'Add :CFBundleLocalizations:1 string de' "$APP/Contents/Info.plist"
/usr/bin/codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"
/usr/bin/codesign --verify --deep --strict "$APP"
printf 'Built %s (%s)\n' "$APP" "$ARCH"
