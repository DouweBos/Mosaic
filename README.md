# Mosaic

A free, open source window manager for macOS that also remembers arrangements: which app goes where, on which display, applied the moment those displays connect.

## Features

- **Snap by dragging**: drag a window to a screen edge and it snaps. Sides give halves, corners quarters, the top maximizes and the bottom edge gives thirds. An outline shows where it will land.
- **Shortcuts for every layout**: halves, quarters, thirds, two thirds, maximize, almost maximize, center, plus next and previous display and restore. All changeable in Settings.
- **Walk across displays**: press a shortcut again on a window that is already there and it moves on to the next display, mirrored. Right half, then the next display's left half, half a display at a time.
- **Arrangements**: save your current layout in one click, or build one in the editor on a picture of your displays. Each app goes on a display, in a region or an exact spot.
- **Apply on connect**: when the displays an arrangement was made for are connected (your dock at the desk, for example), Mosaic puts every app in its place.
- **Apps opened later**: an app that wasn't running when the arrangement applied is put in place as soon as it opens.
- **Gaps** between windows, an **ignore list** for apps Mosaic should leave alone, and **open at login**.

## Default shortcuts

| Shortcut | Layout |
|---|---|
| ⌃⌥← / → / ↑ / ↓ | Left, right, top, bottom half |
| ⌃⌥U / I / J / K | Top left, top right, bottom left, bottom right |
| ⌃⌥D / F / G | First, center, last third |
| ⌃⌥E / T | First, last two thirds |
| ⌃⌥↩ | Maximize |
| ⌃⌥C | Center |
| ⌃⌥⌫ | Restore |
| ⌃⌥⌘→ / ← | Next, previous display |

## Permissions

Mosaic moves other apps' windows through the Accessibility API, so it needs access in System Settings → Privacy & Security → Accessibility. It asks on first launch and notices when access is granted.

## Requirements

- macOS 15 or later
- Accessibility permission (see above)

To build from source you also need Xcode 27 or later. No paid Apple Developer account is needed: Mosaic uses no private frameworks and no entitlements, just the public Accessibility API.

## Download

There are no prebuilt releases yet. Build it from source as described below.

## Building from source

```sh
git clone https://github.com/DouweBos/Mosaic.git
cd Mosaic/app/Mosaic
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' build \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=
open build/Build/Products/Debug/Mosaic.app
```

The last line of the build command signs ad-hoc, so you don't need an Apple ID. To sign with your own team instead, pass `DEVELOPMENT_TEAM=<your team ID>` or pick your team in Xcode under Signing & Capabilities. The only dependency, [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts), is fetched by Swift Package Manager on the first build.

Tests:

```sh
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' test -only-testing:MosaicTests
```

## Project structure

```
app/Mosaic/Mosaic/
  App/            Entry point, app delegate, menu bar menu, Settings window
  Windows/        Accessibility window access, moving and frame math
  Displays/       Identifying displays and noticing when they change
  Snapping/       Drag-to-snap zones, monitor and preview
  Arrangements/   Saving, capturing and applying arrangements
  Settings/       Settings tabs and the arrangement editor
  Models/         Regions, arrangements, settings
  DesignSystem/   Theme and shared components
scripts/          App icon renderer
```

Arrangements are saved in `~/Library/Application Support/Mosaic`.

## Contributing

Bug reports, ideas and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for building, signing, tests and commit conventions, and the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately, as described in [SECURITY.md](SECURITY.md).

## License

Mosaic is released under the [MIT License](LICENSE). Copyright (c) 2026 Douwe Bos.

Made by [Douwe Bos](https://houwert.dev).
