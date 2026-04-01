# MacDitto

MacDitto is a native macOS clipboard history app inspired by Ditto on Windows.

This repo is intentionally standalone. It does not depend on the original Windows Ditto source tree.

## Current Features

- Clipboard history capture using `NSPasteboard`
- Searchable history list
- Pin and unpin items
- Delete individual items
- Clear unpinned items
- Copy an entry back to the clipboard
- Copy and immediately paste an entry
- Menu bar app with popup panel
- Global hotkey toggle with `Cmd+Shift+V`
- Local JSON persistence

## Requirements

- macOS 13 or newer
- Xcode 15 or newer
- Xcode command line tools

## Repo Layout

```text
Package.swift
project.yml
Config/
  App/
  Xcode/
Sources/
  MacDitto/
    Resources/
docs/
scripts/
```

## Quick Start On a Mac

### Swift Package path

```bash
swift build
swift run MacDitto
```

### Xcode project path

Install XcodeGen once:

```bash
brew install xcodegen
```

Then generate and open the native project:

```bash
./scripts/bootstrap-mac.sh
```

That creates `MacDitto.xcodeproj` from [project.yml](C:\Users\jas\Desktop\MacDitto\MacDittoStandaloneRepo\project.yml) and opens it in Xcode.

If you do not want to use XcodeGen, you can still open `Package.swift` directly in Xcode and run the package target.

## Permissions

To use the global hotkey and synthetic paste behavior, macOS may prompt for:

- Accessibility
- Input Monitoring

Check `System Settings` -> `Privacy & Security` if the popup hotkey or auto-paste does not work.

## GitHub Setup

```bash
git remote add origin <your-github-repo-url>
git push -u origin main
```

## Before Release

- Replace `ORGANIZATION_IDENTIFIER` in [Shared.xcconfig](C:\Users\jas\Desktop\MacDitto\MacDittoStandaloneRepo\Config\Xcode\Shared.xcconfig)
- Add your team or personal signing settings in Xcode
- Review the release checklist in [docs/RELEASE.md](C:\Users\jas\Desktop\MacDitto\MacDittoStandaloneRepo\docs\RELEASE.md)
- Use [archive-mac.sh](C:\Users\jas\Desktop\MacDitto\MacDittoStandaloneRepo\scripts\archive-mac.sh) when you are ready to produce a Release archive

## Notes

This is an MVP and not full feature parity with Ditto yet. Rich clipboard formats, configurable shortcuts, startup integration, and distribution polish are still open work.
