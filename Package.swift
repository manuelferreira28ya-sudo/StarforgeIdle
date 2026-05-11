// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StarforgeIdleCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "StarforgeIdle",
            targets: ["StarforgeIdle"]
        )
    ],
    targets: [
        .target(
            name: "StarforgeIdle",
            path: "StarforgeIdle",
            exclude: [
                "Assets.xcassets",
                "ContentView.swift",
                "GameStore.swift",
                "GameViews.swift",
                "PrivacyInfo.xcprivacy",
                "StarforgeIdleApp.swift",
                "Theme.swift"
            ],
            sources: [
                "GameModels.swift",
                "GameEngine.swift"
            ]
        ),
        .testTarget(
            name: "StarforgeIdleTests",
            dependencies: ["StarforgeIdle"],
            path: "StarforgeIdleTests",
            sources: [
                "GameEngineTests.swift"
            ]
        )
    ]
)
