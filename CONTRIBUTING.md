# Contributing to Mosaic

Thanks for your interest in Mosaic. Bug reports, ideas and pull requests are all welcome. For anything bigger than a small fix, open an issue first so we can agree on the approach before you put time in.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report security problems privately, as described in [SECURITY.md](SECURITY.md).

## Requirements

- macOS 15 or later
- Xcode 27 or later
- [SwiftLint](https://github.com/realm/SwiftLint) (`brew install swiftlint`)

No paid Apple Developer account is needed to build and run Mosaic locally.

## Building from source

```sh
git clone https://github.com/DouweBos/Mosaic.git
cd Mosaic/app/Mosaic
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' build
open build/Build/Products/Debug/Mosaic.app --args -MosaicStorage /tmp/mosaic-dev
```

Or open `app/Mosaic/Mosaic.xcodeproj` in Xcode and run the `Mosaic` scheme. Xcode resolves the only remote dependency, [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts), on first build.

### Signing with your own Apple team

The project is set up with the maintainer's development team, which your machine can't sign for. Pick one of:

- **Xcode**: select the `Mosaic` target › Signing & Capabilities and choose your own team (a free Apple ID works). Do the same for `MosaicTests` if you run tests from Xcode.
- **Command line, your team**: append `DEVELOPMENT_TEAM=<your team ID>` to the `xcodebuild` commands.
- **Command line, ad-hoc** (no Apple ID at all): append `CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=`.

Please don't commit a changed `DEVELOPMENT_TEAM` or bundle identifier.

Mosaic needs Accessibility access (System Settings › Privacy & Security › Accessibility). macOS ties that grant to the code signature, so an ad-hoc build may lose it after a rebuild; remove Mosaic from the list and add it again. Signing with a team keeps the grant across builds.

## Running the tests and lint

```sh
cd app/Mosaic
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' test -only-testing:MosaicTests
swiftlint lint --quiet
```

Both must be clean before you open a pull request.

Handy launch arguments for development:

- `-MosaicStorage <path>` keeps arrangements somewhere other than Application Support. Use `/tmp/mosaic-dev` so your real arrangements are left alone.
- `-MosaicOpenSettings general|arrangements|shortcuts|ignored` opens Settings on that tab.
- `-MosaicSelfTest <bundle id>` (Debug builds) moves that app's frontmost window through every region, display walk, capture, apply and launch placement on your real displays, and writes a report to `/tmp/mosaic-selftest.txt`. Point it at a throwaway window, such as a TextEdit document, never one in use.

## How the code is organised

See the [README](README.md#project-structure) for the layout. The short version:

- Plain AppKit app (`main.swift`, no SwiftUI `App`). The menu bar item is an `NSStatusItem` and Settings is a hand-hosted window; give every Settings tab a fixed frame.
- All window access goes through `WindowAccess` and `AXWindow`. Window frames live in accessibility space (top-left origin, y down); keep frame math in `Geometry` so it stays testable.
- Displays are identified by vendor, model and serial (`DisplayIdentity`).
- Settings keys live in `SettingKey`; views bind with `@AppStorage`, services read `Preferences` when they need a value.
- Design system: colors come from `Theme`, SF Symbols only, and reusable components live in `DesignSystem/` with a `#Preview`.
- Keep files under 500 lines and views under 300.
- The app icon and menu bar glyph are generated: edit `scripts/render-icon.swift` and run `swift scripts/render-icon.swift`.

## Commits and pull requests

- One commit per feature, fix or refactor, each with its own tests and docs, so it stands alone and can be reverted.
- Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`, with a short lowercase subject, for example `fix(snapping): ignore drags on fullscreen windows`.
- Comments explain *why*, in a line or two.

Fill in the pull request template, and make sure the tests and lint pass before asking for review.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
