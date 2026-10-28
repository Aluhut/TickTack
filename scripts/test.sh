#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
mkdir -p build/ModuleCache
/usr/bin/xcrun swiftc -D SMOKE_TEST -parse-as-library \
    -module-cache-path build/ModuleCache \
    Sources/TickTack/Models.swift Sources/TickTack/Tracker.swift Sources/TickTack/Localization.swift \
    Sources/TickTack/Transfer.swift Sources/TickTack/Spreadsheet.swift Sources/TickTack/Report.swift Sources/TickTack/TransferUI.swift \
    Tests/TickTackTests/*.swift \
    -framework SwiftUI -framework AppKit -o build/TickTackChecks
./build/TickTackChecks
./build/TickTackChecks -AppleLanguages '(de)'
./build/TickTackChecks -AppleLanguages '(fr, de)'
