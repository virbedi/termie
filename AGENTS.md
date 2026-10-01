# Termie

Native macOS shell grid. Read [agents/skills/termie/SKILL.md](agents/skills/termie/SKILL.md) before changing sessions, attention, or the terminal host.

```sh
swift test --package-path Packages/TermieCore
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build build
```

Keep the app unsandboxed. New behavior for titles or “needs you” belongs in `Packages/TermieCore` with a test.
