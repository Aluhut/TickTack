# Development

## Requirements

- macOS 14+ and Apple's Command Line Tools or Xcode.
- Swift 5.9+ (Swift tools manifest 5.9; system SDK required).
- No external Swift, Python, or JavaScript dependencies. Full Xcode is required for the optional `swift test` XCTest runner; the standalone `./scripts/test.sh` runs the same checks with Command Line Tools alone.

Open `Package.swift` in Xcode for editing. `swift run` launches the executable without creating an installable application bundle. Use `./scripts/build.sh` for a complete app with icon, metadata, and license notices.

## Source layout

- `Models.swift`: Codable entry/project data, sort choices, date parsing.
- `Tracker.swift`: timer, project storage, search-independent ordering, CSV, and restorable deletion.
- `Localization.swift`: German/English strings and deterministic language selection.
- `Views.swift`: sidebar, table, inspector, timer controls, menu bar popover.
- `TickTackApp.swift`: window, application menu commands, dialogs.
- `Tests/TickTackTests`: isolated preference stores and an injected clock.
- `Assets`: original PNG and ICNS logo, both MIT licensed.
- `scripts/RenderIcon.swift`: source for the original icon drawing.

`Tracker` accepts a `UserDefaults` store and clock closure. Tests pass isolated stores and disable the repeating timer. Do not run tests against a person's production preference domain.

## Localization

`Localization(preferredLanguages:)` looks only at the first preferred language. `de`, `de-DE`, and `de_AT` select German. English is the fallback even if German appears later in the list. User content is never localized.

UI strings go through `L(...)`. German keys have English values in `Localization.english`. Persisted sort and color identifiers retain their existing raw values so preferences survive language changes; display labels are translated separately. SwiftUI receives the selected locale for number inputs. Dates written by the app use ISO `YYYY-MM-DD`.

To check both languages without changing system preferences:

```sh
open -n build/TickTack.app --args -AppleLanguages '(de)'
open -n build/TickTack.app --args -AppleLanguages '(en)'
```

Use an isolated macOS account for manual testing of user data. Do not run multiple instances against the same preferences while editing.

## Tests and releases

```sh
./scripts/test.sh
./scripts/package.sh
ARCH=x86_64 ./scripts/package.sh
```

Run `swift test` as an additional check when full Xcode is installed. The standalone runner executes the same behavior checks under default, German, and French-with-German-fallback language preferences.

Both architecture targets can be compiled on a Mac with the corresponding SDK libraries. Runtime validation needs matching hardware or Rosetta. Tests cover language selection, date parsing, project-scoped persistence, timer pauses, sorting, CSV escaping, deletion, and restoration after restart.

The package script creates `dist/TickTack-0.9.0-macOS-<architecture>.zip` and a checksum. Set `VERSION` to change the version. `SIGN_IDENTITY` optionally selects a Developer ID identity. Ad-hoc signing is the default and does not constitute notarization. A public notarized release requires the maintainer's Apple Developer credentials and Apple's notary/stapling workflow; no credentials belong in this repository.

The GitHub Actions workflow runs tests and packages a build on a macOS runner. It uses read-only repository permissions. Add ZIPs and checksums to a tagged GitHub Release after reviewing them. Do not publish `.build`, `build`, test stores, screenshots of real projects, or local preference files.

## Storage and compatibility

The public bundle identifier is `app.ticktack.desktop`. Storage keys include `TickTack.projects`, `TickTack.entries.v1`, `TickTack.deletedItems`, active project, font size, and sort order. The optional bundle metadata key `TickTackLegacyEntriesKey` allows a locally maintained build to migrate an older entry key inside the same preferences domain. Public bundles omit that setting and contain no personal data. Existing records with no project ID are assigned to the first stored project during migration.

Current limitations: in-memory active timer/drafts, no sync or backup import, and no secure erasure of deletion history. CSV is a project report rather than a complete backup format.
