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

## Run

```bash
swift build
swift run MacDitto
```

You can also open `Package.swift` in Xcode and run the `MacDitto` scheme.

## Permissions

To use the global hotkey and synthetic paste behavior, macOS may prompt for:

- Accessibility
- Input Monitoring

Check `System Settings` -> `Privacy & Security` if the popup hotkey or auto-paste does not work.

## Project Layout

```text
Package.swift
Sources/
  MacDitto/
```

## GitHub Setup

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

## Notes

This is an MVP and not full feature parity with Ditto yet. Rich clipboard formats, configurable shortcuts, startup integration, and distribution polish are still open work.
