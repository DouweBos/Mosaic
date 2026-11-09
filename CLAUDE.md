# Mosaic

A free, open source window manager for macOS with saved arrangements that apply when their displays connect. A menu bar app; its setup follows [Grove](https://github.com/DouweBos/Grove).

## Development Guidelines

- This is not a production app. Never plan or implement data migrations — just refactor directly.
- Never name or compare Mosaic to other window managers anywhere in the repository: code, docs, commit messages.
- Plain AppKit app (`main.swift`, no SwiftUI `App`): the menu bar item is an `NSStatusItem` and Settings is a hand-hosted window. Give every Settings tab a fixed frame; grouped forms report no height and the window collapses.
- Window frames live in accessibility space (top-left origin of the main display, y down). Convert Cocoa rects with `Geometry.flip`; keep frame math in `Geometry` so it stays testable.
- All window access goes through `WindowAccess` and `AXWindow`. Nothing moves windows without Accessibility permission; check `WindowAccess.isTrusted`.
- Displays are identified by vendor, model and serial (`DisplayIdentity`), with a left-to-right ordinal for identical monitors.
- Settings keys live in `SettingKey`; views bind with `@AppStorage`, services read `Preferences` at the moment they need a value. Never react synchronously to `UserDefaults.didChangeNotification`: frameworks write defaults mid-layout.

## Design system

1. All colors come from `Theme` (asset catalog tokens, light and dark). No `Color.red`, `Color(red:)`, hex, or `Color(nsColor:)` in views.
2. SF Symbols only, no emoji.
3. Reusable components live in `DesignSystem/`, each with a `#Preview`.

## Build and test

```sh
cd app/Mosaic
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build -destination 'platform=macOS,arch=arm64' build
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build -destination 'platform=macOS,arch=arm64' test -only-testing:MosaicTests
swiftlint lint --quiet
```

Dev launch flags: `-MosaicStorage <path>` keeps arrangements somewhere other than Application Support (use `/tmp/mosaic-dev` when testing), `-MosaicOpenSettings general|arrangements|shortcuts|ignored` opens Settings on that tab. Debug builds also take `-MosaicSelfTest <bundle id>`: it moves that app's frontmost window through every region, display walk, capture, apply and launch placement on the real displays and writes a report to `/tmp/mosaic-selftest.txt`. Point it at a throwaway window (a TextEdit document), never one in use.

The app icon and menu bar glyph are generated: edit `scripts/render-icon.swift` and run `swift scripts/render-icon.swift`.

## Conventions

- Files under 500 lines, views under 300; split when approaching that.
- Commit when a thing is done. Every feature, fix or refactor gets its own commit the moment it works, with its tests and docs in it. Committing is not pushing: push only when asked.
- Commit messages: Conventional Commits, `type(scope): subject`, one short lowercase subject.
- Comments explain why, in 1–2 lines, describing the code as it stands.
