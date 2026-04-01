# Release Notes

## First-Time Setup

1. Set `ORGANIZATION_IDENTIFIER` in [Shared.xcconfig](C:\Users\jas\Desktop\MacDitto\MacDittoStandaloneRepo\Config\Xcode\Shared.xcconfig)
2. Open the generated Xcode project
3. Select the `MacDitto` target
4. Set your Apple Developer team in Signing & Capabilities

## Archive

1. Generate the Xcode project with `./scripts/bootstrap-mac.sh`
2. In Xcode, choose `Any Mac (Apple Silicon, Intel)`
3. Use `Product` -> `Archive`
4. In Organizer, validate the archive and export it

You can also archive from Terminal:

```bash
./scripts/archive-mac.sh
```

For direct distribution, start from [ExportOptions-DeveloperID.plist](C:\Users\jas\Desktop\MacDitto\MacDittoStandaloneRepo\Config\App\ExportOptions-DeveloperID.plist).

## Distribution Notes

- `Accessibility` and `Input Monitoring` are runtime permissions controlled by macOS, not entitlements
- Hardened runtime is enabled in the generated project
- App Sandbox is currently disabled because this app needs system integration that is simpler outside the sandbox for now
