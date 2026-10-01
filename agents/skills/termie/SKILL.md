---
name: termie
description: >-
  Works on Termie, the native macOS bento grid of login shells. Use when
  changing sessions, terminal hosting, Claude or iTerm titles, attention
  states, the grid layout, settings, or the Xcode project.
---

# Termie

## Product

Termie shows several real terminals in one window. The useful case is several Claude Code sessions: each tile keeps a name, tiles that are still running stay quiet, and a tile that needs a person is marked.

## Layout

- App target: `Termie/`, Xcode project `Termie.xcodeproj`. The window, settings, about box, menu bar, and always-on-top behavior come from [simonweniger/swift-macos-template](https://github.com/simonweniger/swift-macos-template) (MIT, see `LICENSE`).
- Pure logic: `Packages/TermieCore`. Title filtering, OSC interpretation, attention, bento frames, and tile dividers live here. Add tests in `Packages/TermieCore/Tests`.
- Tile resize uses `tileDividers` and `resizeTiles`. A drag moves every tile that shares that seam and will not shrink a tile below the minimum. Custom sizes stay until the set of sessions changes. Place divider handles with `position` in the grid, not `offset`; offset leaves the hit target at the top-left. SwiftTerm already applies the new view size to the PTY.
- Terminal view: `Termie/Sessions`. `TermieTerminalView` subclasses SwiftTerm `LocalProcessTerminalView`.

## Shell

Each session runs the user's login shell (`-l`), with `TERM=xterm-256color` and `COLORTERM=truecolor`. That is the same model VS Code and Cursor use, so `.zprofile` / `.zshrc`, Homebrew, and the user's tools apply.

Do not turn the App Sandbox back on. SwiftTerm's local process cannot see the user's files, binaries, or home directory from a sandbox. Entitlements stay empty on purpose.

SwiftTerm is pinned to revision `4d5eeea89ed7c0fabffea9c8415cc392a6a06a31` because that revision exposes `observeOscEvents` and `setProcessOutputHandler`. Do not float the dependency to an older tag.

## Names

Claude sets iTerm tab names with OSC 0/2. `setTerminalTitle` and OSC 0/1/2 both feed `AttentionMonitor`. `automaticSessionTitle` drops bare shell names (`zsh`, `bash`) so a later task title can replace "Terminal". A non-empty name from Rename is stored as `pinnedName` and `displayName` uses it instead of later titles. An empty name, or Use Terminal Title, clears the pin.

## Attention

`AttentionMonitor` is the only place presence changes. Signals:

- Output within the last 0.75s, OSC 9 progress state 1 or 3, or OSC 133 `C`: **working**.
- Bell, OSC 9/99/777 notification, progress error or pause, or progress cleared while the tile is unfocused: **needs you**. A needs-you state stays until the tile is focused or progress reports working again. Further output does not clear it.
- Quiet after working, with no progress and no needs-you signal: **idle**.

New terminals set `TERM_PROGRAM=iTerm.app` when "Use the iTerm channel" is on, so Claude emits the same titles, progress, and notifications it sends iTerm. Bells are caught by overriding `bell(source:)` on the view. `bellStyle` is visual, so the tile flashes without a system beep unless the user turns the beep setting on.

Dock badge and a local notification fire when a background tile starts needing you.

## Build

```sh
swift test --package-path Packages/TermieCore
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build build
```
