# Termie

A native macOS app for working in several shells at once. Sessions sit in one bento grid, pick up the titles Claude already writes into iTerm, and call out the tile that needs you while the others keep running.

Each tile is a real terminal: your login shell, true color, mouse, clipboard, and the same environment VS Code and Cursor hand a terminal. Drag the gap between tiles to resize them.

## Requirements

- macOS 26
- Xcode 26 or newer (Swift 6)

## Build

```sh
swift test --package-path Packages/TermieCore
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build -skipPackagePluginValidation build
open build/Build/Products/Debug/Termie.app
```

The project is signed ad hoc (`CODE_SIGN_IDENTITY = "-"`) and `DEVELOPMENT_TEAM` is empty, so a clone builds without an Apple Developer account. The app is not sandboxed. A sandbox would hide your files and tools from the shell. Entitlements in `Termie/Termie.entitlements` stay empty for that reason.

## Where things live

- `Termie/` is the SwiftUI app.
- `Packages/TermieCore` is the title, attention, layout, and resize logic, with tests.
- `agents/skills/termie` is the project skill for agents working in this repo. `.cursor/skills/termie` is a symlink to it.

## Third-party

- The window, settings, about box, and menu bar started from [swift-macos-template](https://github.com/simonweniger/swift-macos-template) by Simon Weniger (MIT).
- Terminal emulation is [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) by Miguel de Icaza and contributors (MIT), pinned to commit `4d5eeea89ed7c0fabffea9c8415cc392a6a06a31`.

## License

[MIT](LICENSE). Copyright (c) 2026 Vir Bedi. The original template notice, Copyright (c) 2023 Simon Weniger, remains in `LICENSE`.
