# Starforge Idle

Native SwiftUI idle game for iOS.

## Gameplay

Starforge Idle uses a proven casual idle structure: tap for a first resource, buy generators, upgrade multipliers, complete goals, unlock crew, earn while away, and prestige into permanent prism power.

Implemented systems:

- Forge tap core
- Eight generator tiers
- Generator milestone boosts at x10, x25, x50, and x100
- Ten upgrade branches
- Goal chain with stardust, prism, and crew rewards
- Crew collection bonuses
- Daily supply gated behind first progression
- Offline earnings with upgradeable cap
- Prestige launch confirmation
- Versioned local save envelope with legacy decode fallback

## Development

The iOS app target requires macOS with Xcode 26+ for App Store submission builds.

The economy core can be tested on Windows after installing Swift and Visual Studio Build Tools:

```powershell
.\scripts\Test-Core.ps1
```

## App Store

Submission notes, metadata drafts, privacy/support drafts, screenshot guidance, and final Mac validation commands live in `AppStore/APP_STORE_READINESS.md` and `fastlane/metadata/en-US`.
