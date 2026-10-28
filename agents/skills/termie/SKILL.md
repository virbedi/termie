---
name: termie
description: >-
  Works on Termie, the native macOS bento grid of login shells. Use when
  changing sessions, terminal hosting, Claude or iTerm titles, the grid
  layout, settings, or the Xcode project.
---

# Termie

## Product

Termie shows several real terminals in one window. The useful case is several AI agent and server/simulator sessions : tiles are named and can be managed and viewed together.

## Layout

- App target: `Termie/`, Xcode project `Termie.xcodeproj`. The window, settings, about box, menu bar, and always-on-top behavior come from [simonweniger/swift-macos-template](https://github.com/simonweniger/swift-macos-template) (MIT, see `LICENSE`).
- Pure logic: `Packages/TermieCore`. Title filtering, OSC interpretation, equal canvas frames, session reorder, and per-shell themes live here. Add tests in `Packages/TermieCore/Tests`.
- The main canvas starts from `equalGridFrames` so visible sessions occupy nearly equal windows in reading order. Drag a window by its title bar; it follows the pointer and may cover the others until drop. On drop, `canvasDropSlot` plus `reorderOccupyingSlot` pack the windows back into a non-overlapping reading order. Drag any edge (`resizeTileEdge`) or corner (`resizeTileCorner`) to resize that window alone. If it covers another window, `revealCoveredWindows` shrinks the covered one out of the overlap, never below the minimum span, and stops the covering window at that footprint. Windows that still overlap draw smallest-on-top via `drawsAboveOverlappingWindows`. The hit targets are invisible and placed with `position` in the grid, not `offset`. Custom sizes stay until the session set changes or Equalize runs. The focused terminal is the one with the accent border. Focus does not change which slot a window occupies. **⌘⇧G** (Equalize Grid) clears custom sizes and snaps back to the predetermined equal layout.
- App chrome follows the global default `ShellTheme` (`settings.defaultTheme`), not the focused tile. New terminals start on that same default. Click the color swatch, the context menu, or **⌘⇧D** to cycle a tile through dark, light, deep blue, gray, and deep green. `TerminalHost` pushes SwiftTerm colors from that theme; tile chrome is painted from the palette and must not set `preferredColorScheme`.
- Terminal view: `Termie/Sessions`. `TermieTerminalView` subclasses SwiftTerm `LocalProcessTerminalView`. Start the login shell from a usable frame (`onUsableSize` / `startIfNeeded`), not only from `updateNSView`—SwiftUI often updates the representable while bounds are still zero when a tile is added. Dropping files or a screenshot on a terminal inserts `shellDropText` at the cursor: single-quoted paths, no newline. A screenshot that is only image data is written under the temporary `Termie` directory first. File promises use the same insertion once the file arrives.

## Shell

Each session runs the user's login shell (`-l`), with `TERM=xterm-256color` and `COLORTERM=truecolor`. That is the same model VS Code and Cursor use, so `.zprofile` / `.zshrc`, Homebrew, and the user's tools apply.

Do not turn the App Sandbox back on. SwiftTerm's local process cannot see the user's files, binaries, or home directory from a sandbox. Entitlements stay empty on purpose.

SwiftTerm is pinned to revision `4d5eeea89ed7c0fabffea9c8415cc392a6a06a31` because that revision exposes `observeOscEvents` and `setProcessOutputHandler`. Do not float the dependency to an older tag.

## Names

Claude sets iTerm tab names with OSC 0/2. `setTerminalTitle` and OSC 0/1/2 both feed `automaticSessionTitle`, which drops bare shell names (`zsh`, `bash`) so a later task title can replace "Terminal". A non-empty name from Rename is stored as `pinnedName` and `displayName` uses it instead of later titles. An empty name, or Use Terminal Title, clears the pin. The Terminal menu lists jump targets by session, not by a raw index, so closing a tile cannot crash the menu. OSC 9/99/777 notifications, progress, and shell marks are parsed and ignored. A session is `running` or `exited`; there is no working or needs-you state.

New terminals set `TERM_PROGRAM=iTerm.app` when "Use the iTerm channel" is on, so Claude emits the same titles it sends iTerm. `bellStyle` is visual, so a bell flashes the tile without a system beep or a status change.

## Build

```sh
swift test --package-path Packages/TermieCore
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build build
```
