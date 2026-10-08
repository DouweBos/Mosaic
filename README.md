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
- Xcode 27 to build

## Building

```sh
cd app/Mosaic
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build -destination 'platform=macOS,arch=arm64' build
open build/Build/Products/Debug/Mosaic.app
```

Tests:

```sh
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build -destination 'platform=macOS,arch=arm64' test -only-testing:MosaicTests
```

To build with your own Apple ID, change the development team in the project's Signing & Capabilities.

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

## License

MIT
