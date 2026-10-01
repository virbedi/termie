<p align="center">
  <img src="Termie/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="160" alt="Termie">
</p>

<h1 align="center">Termie</h1>

<p align="center">Several real terminals, one window.</p>

Termie is a native macOS app for watching more than one shell at a time. It is built for [Claude Code](https://code.claude.com): a session only needs you for the moment it stops and asks something, so the useful setup is several of them in one view. Each tile keeps a name, tiles that are still working stay quiet, and the one that needs you is marked.

A tile is your login shell. Your PATH, dotfiles, mouse, and clipboard are the ones you already use in Terminal, VS Code, or Cursor. Termie does not wrap the shell or add its own keybinding grammar.

There is no downloadable build yet. You build it from source, and it runs on macOS only.

## Install

You need macOS 26 and Xcode 26 or newer.

```sh
git clone https://github.com/virbedi/termie.git
cd termie
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build -skipPackagePluginValidation build
open build/Build/Products/Debug/Termie.app
```

No Apple Developer account is required. The build is ad hoc signed, and a copy you produce this way opens normally. Termie is not sandboxed, so the shell can see your files, Homebrew, and the rest of your tools. The first window opens one login shell in your home folder.

## Working with Claude Code

Running an agent is not the same as running a command. A session lasts a long time, spends most of it working, and only needs you when it stops. Termie is arranged around that.

- **Tiles name themselves.** Claude already publishes a short title into iTerm tabs. Termie reads that same title, so a tile can say “fix auth” instead of `zsh`. Rename it from the tile, the sidebar, or **Terminal → Rename Terminal**. That name stays when Claude changes the title. **Use Terminal Title** lets Claude name it again. Double-clicking the name still starts a rename.
- **A tile tells you when it wants you.** While Claude is printing or showing progress, the tile says **Working**. When it rings the bell, sends a notification, or finishes and waits, that tile turns orange where it already sits, and the Dock badge updates. It does not move. If Termie is in the background you also get a notification. Focus the tile to clear it. A shell that has simply gone quiet is **Idle**.
- **New terminals talk the iTerm channel.** That setting is on by default, which is why Claude sends those titles and pings. It applies to terminals you open after you change it.

If a session finishes and the tile stays idle, ask Claude to ring the bell as well. In `~/.claude/settings.json`:

```json
{
  "preferredNotifChannel": "terminal_bell"
}
```

**Option as Esc** is on by default. That is the key setting Claude Code shortcuts expect, the same one iTerm calls “Esc+”.

## Use the window

**⌘T** opens a terminal. **⌘W** closes the one you are typing in. **⌘⇧R** restarts it.

Drag the grip in the gap between tiles to resize them. Two tiles split the window. Three give a large tile beside a stack. Four make a cross. Focusing a tile, or marking it as needing you, does not move it. Sizes stay until you drag a divider or add or close a session.

| Shortcut | |
| --- | --- |
| **⌘]** / **⌘[** | Next and previous tile |
| **⌘1**–**⌘9** | Jump to a tile |
| Menu bar icon | Every session, with the ones that need you called out |
| Window → Always on Top | Keep the grid above other windows |

New terminals start in the focused session’s folder. Settings can point them at your home directory, or at a folder you type, and can change the font size. **Beep when a terminal needs you** is off until you turn it on.

## For contributors

```sh
swift test --package-path Packages/TermieCore
```

`Termie/` is the app. `Packages/TermieCore` holds title, attention, layout, and resize logic, with tests. Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing those.

## Credits

- Window, settings, about box, and menu bar started from [swift-macos-template](https://github.com/simonweniger/swift-macos-template) by Simon Weniger (MIT).
- Terminal emulation is [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) by Miguel de Icaza and contributors (MIT).

## License

[MIT](LICENSE). Copyright (c) 2026 Vir Bedi. Copyright (c) 2023 Simon Weniger remains on the template.
