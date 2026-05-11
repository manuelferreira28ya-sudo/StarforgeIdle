# Testing Without a Mac

You cannot run the iOS Simulator directly on Windows. The practical replacement is a cloud macOS build plus either a browser simulator or TestFlight.

## Option A: GitHub Actions + Browser Simulator

1. Push to `main` or open the repository on GitHub.
2. Go to **Actions**.
3. Run **iOS Build and Core Tests**.
4. Wait for both jobs to pass.
5. Download the `StarforgeIdle-simulator-app` artifact.
6. Upload `StarforgeIdle-simulator.zip` to Appetize or another service that accepts iOS Simulator `.app` bundles.

This lets you click through the game in a browser without owning a Mac.

## Option B: GitHub Actions + TestFlight

Use a cloud CI service or GitHub Actions macOS runner to archive and upload to App Store Connect. This requires:

- Apple Developer Program membership
- App Store Connect app record
- Signing certificate
- Provisioning profile
- App Store Connect API key

After upload, install the game on your iPhone through TestFlight.

## Option C: Rent a Cloud Mac

Use a rented Mac service, install Xcode 26+, clone the repo, and run:

```bash
xcodebuild -project StarforgeIdle.xcodeproj -scheme StarforgeIdle -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' clean test
```

This is closest to owning a Mac and is best for manual Simulator testing.

