# Termie

A native macOS app for working in several shells at once. Sessions sit in one bento grid, pick up the titles Claude already writes into iTerm, and call out the tile that needs you while the others keep running.

Each tile is a real terminal: your login shell, true color, mouse, clipboard, and the same environment VS Code and Cursor hand a terminal.

## Build

```sh
swift test --package-path Packages/TermieCore
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build build
open build/Build/Products/Debug/Termie.app
```

The app is not sandboxed. A sandbox would hide the rest of your machine from the shell.

## Where things live

- `Termie/` is the SwiftUI app, started from [swift-macos-template](https://github.com/simonweniger/swift-macos-template).
- `Packages/TermieCore` is the title, attention, and layout logic, with tests.
- `agents/skills/termie` is the project skill for agents working in this repo.
