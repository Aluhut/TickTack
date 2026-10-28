#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
./scripts/build.sh
mkdir -p dist
ARCH="${ARCH:-$(uname -m)}"
ARCHIVE="dist/TickTack-${VERSION:-0.10.0}-macOS-$ARCH.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent build/TickTack.app "$ARCHIVE"
/usr/bin/shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"
printf 'Packaged %s\n' "$ARCHIVE"
