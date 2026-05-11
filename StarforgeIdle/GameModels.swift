import Foundation

struct GameState: Codable, Equatable {
    var stardust: Double
    var totalStardustEarned: Double
    var lifetimeTaps: Int
    var prisms: Int
    var prestigeLevel: Int
    var generators: [GeneratorState]
    var upgrades: [UpgradeState]
    var claimedGoalIDs: Set<String>
    var crewIDs: Set<String>
    var lastDailyClaimAt: Date?
    var dailyStreak: Int
    var lastSavedAt: Date
    var lastOfflineReward: Double
    var createdAt: Date

    init(now: Date = Date()) {
        stardust = 0
        totalStardustEarned = 0
        lifetimeTaps = 0
        prisms = 0
        prestigeLevel = 0
        generators = GameBalance.generatorCatalog.map { GeneratorState(id: $0.id, count: 0) }
        upgrades = GameBalance.upgradeCatalog.map { UpgradeState(id: $0.id, level: 0) }
        claimedGoalIDs = []
        crewIDs = []
        lastDailyClaimAt = nil
        dailyStreak = 0
        lastSavedAt = now
        lastOfflineReward = 0
        createdAt = now
    }
}

struct GeneratorState: Identifiable, Codable, Equatable {
    let id: String
    var count: Int
}

struct UpgradeState: Identifiable, Codable, Equatable {
    let id: String
    var level: Int
}

struct GeneratorDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let role: String
    let symbolName: String
    let baseCost: Double
    let baseOutput: Double
    let costGrowth: Double
    let unlockAtTotalEarned: Double
}

struct UpgradeDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let detail: String
    let symbolName: String
    let baseCost: Double
    let costGrowth: Double
    let maxLevel: Int
    let effect: UpgradeEffect
    let effectPerLevel: Double
}

enum UpgradeEffect: Codable, Equatable {
    case tapValue
    case globalProduction
    case generatorProduction(String)
    case offlineWindow
}

struct GoalDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let completeWhen: String
    let metric: GoalMetric
    let reward: GoalReward
}

enum GoalMetric: Codable, Equatable {
    case lifetimeTaps(Int)
    case totalStardust(Double)
    case generatorCount(String, Int)
    case upgradeLevels(Int)
    case passiveIncome(Double)
    case crewUnlocked(Int)
    case prisms(Int)
}

enum GoalReward: Codable, Equatable {
    case stardust(Double)
    case prism(Int)
    case crew(String)
}

struct CrewDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let role: String
    let rarity: String
    let symbolName: String
    let bonusPercentage: Double
}

struct GoalProgress: Equatable {
    let current: Double
    let target: Double

    var fraction: Double {
        guard target > 0 else { return 1 }
        return min(current / target, 1)
    }

    var isComplete: Bool {
        current >= target
    }
}

enum GameBalance {
    static let baseOfflineCap: TimeInterval = 8 * 60 * 60
    static let prestigeThreshold: Double = 100_000
    static let dailyBaseReward: Double = 180

    static let generatorCatalog: [GeneratorDefinition] = [
        GeneratorDefinition(
            id: "spark-kiln",
            name: "Spark Kiln",
            role: "Steady starter income",
            symbolName: "flame.fill",
            baseCost: 15,
            baseOutput: 0.2,
            costGrowth: 1.14,
            unlockAtTotalEarned: 0
        ),
        GeneratorDefinition(
            id: "drone-dock",
            name: "Drone Dock",
            role: "Fast midgame ramp",
            symbolName: "airplane",
            baseCost: 125,
            baseOutput: 1.6,
            costGrowth: 1.16,
            unlockAtTotalEarned: 90
        ),
        GeneratorDefinition(
            id: "orbital-bazaar",
            name: "Orbital Bazaar",
            role: "Compounding trade routes",
            symbolName: "shippingbox.fill",
            baseCost: 1_250,
            baseOutput: 14,
            costGrowth: 1.18,
            unlockAtTotalEarned: 900
        ),
        GeneratorDefinition(
            id: "quantum-orchard",
            name: "Quantum Orchard",
            role: "Late-session burst income",
            symbolName: "sparkles",
            baseCost: 12_500,
            baseOutput: 120,
            costGrowth: 1.2,
            unlockAtTotalEarned: 9_000
        )
    ]

    static let upgradeCatalog: [UpgradeDefinition] = [
        UpgradeDefinition(
            id: "tap-rig",
            name: "Tap Rig",
            detail: "Bigger rewards per tap",
            symbolName: "hand.tap.fill",
            baseCost: 60,
            costGrowth: 2.0,
            maxLevel: 10,
            effect: .tapValue,
            effectPerLevel: 0.55
        ),
        UpgradeDefinition(
            id: "solar-contracts",
            name: "Solar Contracts",
            detail: "Raises all passive income",
            symbolName: "sun.max.fill",
            baseCost: 240,
            costGrowth: 2.35,
            maxLevel: 8,
            effect: .globalProduction,
            effectPerLevel: 0.16
        ),
        UpgradeDefinition(
            id: "drone-ai",
            name: "Drone AI",
            detail: "Boosts Drone Dock output",
            symbolName: "cpu.fill",
            baseCost: 520,
            costGrowth: 2.15,
            maxLevel: 8,
            effect: .generatorProduction("drone-dock"),
            effectPerLevel: 0.28
        ),
        UpgradeDefinition(
            id: "market-routes",
            name: "Market Routes",
            detail: "Boosts Orbital Bazaar output",
            symbolName: "arrow.triangle.branch",
            baseCost: 2_800,
            costGrowth: 2.25,
            maxLevel: 7,
            effect: .generatorProduction("orbital-bazaar"),
            effectPerLevel: 0.32
        ),
        UpgradeDefinition(
            id: "time-bank",
            name: "Time Bank",
            detail: "Extends offline earnings",
            symbolName: "clock.badge.checkmark.fill",
            baseCost: 6_500,
            costGrowth: 2.5,
            maxLevel: 4,
            effect: .offlineWindow,
            effectPerLevel: 0.25
        )
    ]

    static let crewCatalog: [CrewDefinition] = [
        CrewDefinition(
            id: "nova",
            name: "Nova",
            role: "Launch captain",
            rarity: "Rare",
            symbolName: "star.fill",
            bonusPercentage: 0.05
        ),
        CrewDefinition(
            id: "mira",
            name: "Mira",
            role: "Upgrade engineer",
            rarity: "Epic",
            symbolName: "wrench.and.screwdriver.fill",
            bonusPercentage: 0.08
        ),
        CrewDefinition(
            id: "sol",
            name: "Sol",
            role: "Offline operator",
            rarity: "Legendary",
            symbolName: "moon.stars.fill",
            bonusPercentage: 0.12
        )
    ]

    static let goalCatalog: [GoalDefinition] = [
        GoalDefinition(
            id: "wake-the-forge",
            name: "Wake the Forge",
            description: "Tap 10 times",
            completeWhen: "player lifetime taps reaches 10",
            metric: .lifetimeTaps(10),
            reward: .stardust(45)
        ),
        GoalDefinition(
            id: "first-glow",
            name: "First Glow",
            description: "Earn 250 total stardust",
            completeWhen: "player total stardust earned reaches 250",
            metric: .totalStardust(250),
            reward: .crew("nova")
        ),
        GoalDefinition(
            id: "drone-shift",
            name: "Drone Shift",
            description: "Own 1 Drone Dock",
            completeWhen: "player owns at least 1 Drone Dock",
            metric: .generatorCount("drone-dock", 1),
            reward: .stardust(160)
        ),
        GoalDefinition(
            id: "power-curve",
            name: "Power Curve",
            description: "Reach 25 stardust/sec",
            completeWhen: "passive income reaches 25 stardust per second",
            metric: .passiveIncome(25),
            reward: .prism(1)
        ),
        GoalDefinition(
            id: "crew-briefing",
            name: "Crew Briefing",
            description: "Buy 3 upgrade levels",
            completeWhen: "total upgrade levels reaches 3",
            metric: .upgradeLevels(3),
            reward: .crew("mira")
        ),
        GoalDefinition(
            id: "signal-boost",
            name: "Signal Boost",
            description: "Unlock 2 crew members",
            completeWhen: "player has 2 crew members",
            metric: .crewUnlocked(2),
            reward: .stardust(2_500)
        ),
        GoalDefinition(
            id: "first-prism",
            name: "First Prism",
            description: "Collect 2 prisms",
            completeWhen: "player has at least 2 prisms",
            metric: .prisms(2),
            reward: .crew("sol")
        )
    ]
}

extension GameState {
    func generatorCount(for id: String) -> Int {
        generators.first(where: { $0.id == id })?.count ?? 0
    }

    mutating func setGeneratorCount(_ count: Int, for id: String) {
        if let index = generators.firstIndex(where: { $0.id == id }) {
            generators[index].count = count
        } else {
            generators.append(GeneratorState(id: id, count: count))
        }
    }

    func upgradeLevel(for id: String) -> Int {
        upgrades.first(where: { $0.id == id })?.level ?? 0
    }

    mutating func setUpgradeLevel(_ level: Int, for id: String) {
        if let index = upgrades.firstIndex(where: { $0.id == id }) {
            upgrades[index].level = level
        } else {
            upgrades.append(UpgradeState(id: id, level: level))
        }
    }
}
