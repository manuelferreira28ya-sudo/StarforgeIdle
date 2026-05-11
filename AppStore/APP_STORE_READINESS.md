# Starforge Idle App Store Readiness

This repo is prepared for a native iOS App Store submission, with the account-side items separated from source-controlled code.

## Current App

- Bundle ID: `com.manuelferreira.starforgeidle`
- Display name: `Starforge Idle`
- Category: Games
- Minimum deployment target: iOS 16.0
- Required upload toolchain as of May 11, 2026: Xcode 26 or later with the iOS 26 SDK or later.
- Privacy manifest: `StarforgeIdle/PrivacyInfo.xcprivacy`
- Tracking: none
- Data collection in app code: none
- Persistence: local UserDefaults game progress only
- Monetization in this build: none

## Final Mac Validation

Run these on macOS with Xcode 26+ installed:

```bash
xcodebuild -project StarforgeIdle.xcodeproj -scheme StarforgeIdle -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' clean test
xcodebuild -project StarforgeIdle.xcodeproj -scheme StarforgeIdle -configuration Release -destination 'generic/platform=iOS' archive
plutil -lint StarforgeIdle/PrivacyInfo.xcprivacy
```

## App Store Connect Fields

- Name: Starforge Idle
- Subtitle: Tap, build, launch again
- Category: Games
- Content rights: original app, original icon, no third-party media
- Age rating: answer current App Store Connect questions for a casual idle game with no ads, no gambling, no user-generated content, and no web access.
- Privacy: no tracking, no collected data. Required reason API: UserDefaults, reason `CA92.1`.
- Privacy policy URL: `https://github.com/manuelferreira28ya-sudo/StarforgeIdle/blob/main/docs/privacy.md`
- Support URL: `https://github.com/manuelferreira28ya-sudo/StarforgeIdle/blob/main/docs/support.md`
- Review notes: use `fastlane/metadata/en-US/review_information.txt`.

## Screenshots

Apple requires one to ten screenshots in accepted `.png`, `.jpg`, or `.jpeg` sizes. Current 6.9-inch portrait accepted sizes include `1260x2736`, `1290x2796`, or `1320x2868`.

Capture real gameplay screenshots from a simulator or device after the Xcode validation pass. Recommended shots:

1. Forge tab with the featured goal and tap core.
2. Build tab with prestige panel and upgrade list.
3. Goals tab with quest chain progress.
4. Crew tab with unlocked and locked crew.
5. Supply tab with daily and offline systems.

## Account-Specific Items

These cannot be committed safely because they belong to the Apple Developer account or require an App Store Connect session:

- `DEVELOPMENT_TEAM`
- Signing certificates and provisioning profiles
- App Store Connect app record
- Final screenshot upload
