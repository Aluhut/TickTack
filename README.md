<p align="center"><img src="Assets/AppIcon.png" width="128" alt="TickTack clock icon"></p>
<h1 align="center">TickTack</h1>
<p align="center">Native project time tracking for macOS. Start, pause, and keep your work in view.</p>
<p align="center">macOS 14+ · SwiftUI · English & Deutsch · MIT</p>

[Deutsche Anleitung](docs/README.de.md) · [User guide](docs/USER_GUIDE.md) · [Development](docs/DEVELOPMENT.md) · [Privacy](docs/PRIVACY.md)

TickTack is a small, local-first Mac app for tracking time across projects. Use the menu bar timer while you work, then review and edit your entries in a native table. No account, subscription, or network connection is required.

## Features

- Start, pause, resume, and save with large, clearly labelled controls.
- Separate projects with six accent colors and prominent live project totals.
- Editable tasks, categories, descriptions, date ranges, and decimal hours.
- Manual entries alongside timed work.
- Search and sorting by date, task, category, or hours.
- Delete multiple entries or entire projects, then restore deletions across restarts.
- Project-scoped CSV export for Numbers, Excel, and other spreadsheet tools.
- Readable 17-point base text, adjustable from 16 to 24 points.
- Automatic language selection: German when the primary system language is German; English for every other language.

## Install

TickTack requires macOS 14 (Sonoma) or later.

Download a ready-to-use app from [Releases](https://github.com/Aluhut/TickTack/releases/latest):

- [Apple silicon (M1 and later)](https://github.com/Aluhut/TickTack/releases/download/v0.9.0/TickTack-0.9.0-macOS-arm64.zip)
- [Intel Mac](https://github.com/Aluhut/TickTack/releases/download/v0.9.0/TickTack-0.9.0-macOS-x86_64.zip)

Extract the ZIP and drag **TickTack.app** to **Applications**. These builds are ad-hoc signed and not notarized; see the security note below.

### Build from source

Build on your Mac using Apple's Command Line Tools:

```sh
xcode-select --install
./scripts/build.sh
open build/TickTack.app
```

Download this repository using GitHub's **Code → Download ZIP**, extract it, and run these commands from the extracted directory. You can also open `Package.swift` in Xcode, or clone the repository using the URL from its **Code** menu.

Drag `build/TickTack.app` into **Applications** to install it. Launch it from Applications or Spotlight. Building locally produces an app for your Mac's architecture. Intel builds use `ARCH=x86_64 ./scripts/build.sh`; Apple silicon builds use `ARCH=arm64 ./scripts/build.sh`.

Build archives are ad-hoc signed unless a Developer ID signing identity is supplied. They are not notarized by default. Downloaded archives may require an explicit macOS security approval. See [Apple's instructions for opening apps](https://support.apple.com/102445). No security settings need to be disabled.

## First steps

1. Choose **File → New project…** (⌘N), enter a name, and choose a color.
2. Click **New entry** and describe your task.
3. Press **Start**, use **Pause** when needed, then **Stop & save**.
4. Select a row to edit all its details in the right-hand panel.
5. Export the selected project's saved entries with **Export CSV**.

To add time manually, enter decimal hours in **New entry** and click **Add entry**. For example, 1.5 hours is 90 minutes; German input uses the decimal comma.

## Data and limitations

Data stays in your Mac's application preferences. New installations contain no example projects or client data. No analytics, telemetry, advertising, or remote service is included.

Saved entries and deletion history survive restarts. **Save a running measurement before quitting:** active measurements and unfinished draft text are currently held in memory. A crash, force quit, or standard app quit can lose an unsaved measurement. The menu bar's Quit button saves an active measurement first.

There is no cloud sync, automatic backup, or in-app backup import. CSV is an export of saved entries, not a complete application backup. The live total includes the running measurement; the CSV does not include it until it is stopped and saved. See the [user guide](docs/USER_GUIDE.md) for details.

## Build and test

```sh
./scripts/test.sh
./scripts/package.sh
```

The package script creates an application ZIP and SHA-256 checksum in `dist/`. The repository's GitHub Actions workflow builds and tests on macOS and uploads an application artifact. See [Development](docs/DEVELOPMENT.md) for architecture, localization, and release instructions.

## Contributing

Bug reports, usability improvements, and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first. Please use fictional project data in screenshots and reports.

## License

The source, documentation, and original TickTack logo are available under the [MIT License](LICENSE). Apple's frameworks, system fonts, and system symbols remain subject to Apple's terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
