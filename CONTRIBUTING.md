# Contributing

Open `Termie.xcodeproj` and build the Termie scheme. Before changing sessions, titles, attention, or the terminal host, read `agents/skills/termie/SKILL.md`.

Logic for titles, attention, bento frames, and tile dividers belongs in `Packages/TermieCore`, with a test next to the change.

```sh
swift test --package-path Packages/TermieCore
xcodebuild -project Termie.xcodeproj -scheme Termie -destination 'platform=macOS' -derivedDataPath build -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build
```

Leave the app unsandboxed. Do not commit a development team, provisioning profile, or `xcuserdata`.
