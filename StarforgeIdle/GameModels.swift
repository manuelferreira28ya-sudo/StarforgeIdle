import Foundation

struct SavedGameEnvelope: Codable, Equatable {
    static let currentVersion = 2

    let version: Int
    let state: GameState

    init(state: GameState, version: Int = SavedGameEnvelope.currentVersion) {
        self.version = version
        self.state = state
    }
}

struct GameState: Codable, Equatable {
    var saveVersion: Int
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
        saveVersion = 2
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

    enum CodingKeys: String, CodingKey {
        case saveVersion
        case stardust
        case totalStardustEarned
        case lifetimeTaps
        case prisms
        case prestigeLevel
        case generators
        case upgrades
        case claimedGoalIDs
        case crewIDs
        case lastDailyClaimAt
        case dailyStreak
        case lastSavedAt
        case lastOfflineReward
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()
        saveVersion = try container.decodeIfPresent(Int.self, forKey: .saveVersion) ?? 1
        stardust = try container.decodeIfPresent(Double.self, forKey: .stardust) ?? 0
        totalStardustEarned = try container.decodeIfPresent(Double.self, forKey: .totalStardustEarned) ?? stardust
        lifetimeTaps = try container.decodeIfPresent(Int.self, forKey: .lifetimeTaps) ?? 0
        prisms = try container.decodeIfPresent(Int.self, forKey: .prisms) ?? 0
        prestigeLevel = try container.decodeIfPresent(Int.self, forKey: .prestigeLevel) ?? 0
        claimedGoalIDs = try container.decodeIfPresent(Set<String>.self, forKey: .claimedGoalIDs) ?? []
        crewIDs = try container.decodeIfPresent(Set<String>.self, forKey: .crewIDs) ?? []
        lastDailyClaimAt = try container.decodeIfPresent(Date.self, forKey: .lastDailyClaimAt)
        dailyStreak = try container.decodeIfPresent(Int.self, forKey: .dailyStreak) ?? 0
        lastSavedAt = try container.decodeIfPresent(Date.self, forKey: .lastSavedAt) ?? now
        lastOfflineReward = try container.decodeIfPresent(Double.self, forKey: .lastOfflineReward) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now

        let savedGenerators = try container.decodeIfPresent([GeneratorState].self, forKey: .generators) ?? []
        let savedUpgrades = try container.decodeIfPresent([UpgradeState].self, forKey: .upgrades) ?? []
        generators = GameState.mergedGenerators(savedGenerators)
        upgrades = GameState.mergedUpgrades(savedUpgrades)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(2, forKey: .saveVersion)
        try container.encode(stardust, forKey: .stardust)
        try container.encode(totalStardustEarned, forKey: .totalStardustEarned)
        try container.encode(lifetimeTaps, forKey: .lifetimeTaps)
        try container.encode(prisms, forKey: .prisms)
        try container.encode(prestigeLevel, forKey: .prestigeLevel)
        try container.encode(generators, forKey: .generators)
        try container.encode(upgrades, forKey: .upgrades)
        try container.encode(claimedGoalIDs, forKey: .claimedGoalIDs)
        try container.encode(crewIDs, forKey: .crewIDs)
        try container.encodeIfPresent(lastDailyClaimAt, forKey: .lastDailyClaimAt)
        try container.encode(dailyStreak, forKey: .dailyStreak)
        try container.encode(lastSavedAt, forKey: .lastSavedAt)
        try container.encode(lastOfflineReward, forKey: .lastOfflineReward)
        try container.encode(createdAt, forKey: .createdAt)
    }

    private static func mergedGenerators(_ saved: [GeneratorState]) -> [GeneratorState] {
        GameBalance.generatorCatalog.map { definition in
            saved.first(where: { $0.id == definition.id }) ?? GeneratorState(id: definition.id, count: 0)
        }
    }

    private static func mergedUpgrades(_ saved: [UpgradeState]) -> [UpgradeState] {
        GameBalance.upgradeCatalog.map { definition in
            saved.first(where: { $0.id == definition.id }) ?? UpgradeState(id: definition.id, level: 0)
        }
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
    case prestigeLevel(Int)
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
    static let milestoneCounts = [10, 25, 50, 100]

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
        ),
        GeneratorDefinition(
            id: "nebula-mine",
            name: "Nebula Mine",
            role: "Deep run extraction",
            symbolName: "circle.hexagongrid.fill",
            baseCost: 95_000,
            baseOutput: 920,
            costGrowth: 1.21,
            unlockAtTotalEarned: 65_000
        ),
        GeneratorDefinition(
            id: "fusion-array",
            name: "Fusion Array",
            role: "High-output reactor grid",
            symbolName: "atom",
            baseCost: 720_000,
            baseOutput: 7_400,
            costGrowth: 1.22,
            unlockAtTotalEarned: 450_000
        ),
        GeneratorDefinition(
            id: "comet-foundry",
            name: "Comet Foundry",
            role: "Prestige-run accelerator",
            symbolName: "meteors",
            baseCost: 5_800_000,
            baseOutput: 62_000,
            costGrowth: 1.23,
            unlockAtTotalEarned: 3_600_000
        ),
        GeneratorDefinition(
            id: "singularity-loom",
            name: "Singularity Loom",
            role: "Endgame stardust fabric",
            symbolName: "circle.dotted.circle",
            baseCost: 44_000_000,
            baseOutput: 520_000,
            costGrowth: 1.24,
            unlockAtTotalEarned: 26_000_000
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
        ),
        UpgradeDefinition(
            id: "kiln-tuning",
            name: "Kiln Tuning",
            detail: "Boosts Spark Kiln output",
            symbolName: "slider.horizontal.3",
            baseCost: 750,
            costGrowth: 2.05,
            maxLevel: 8,
            effect: .generatorProduction("spark-kiln"),
            effectPerLevel: 0.24
        ),
        UpgradeDefinition(
            id: "orchard-grafting",
            name: "Orchard Grafting",
            detail: "Boosts Quantum Orchard output",
            symbolName: "leaf.fill",
            baseCost: 18_000,
            costGrowth: 2.22,
            maxLevel: 7,
            effect: .generatorProduction("quantum-orchard"),
            effectPerLevel: 0.34
        ),
        UpgradeDefinition(
            id: "nebula-survey",
            name: "Nebula Survey",
            detail: "Boosts Nebula Mine output",
            symbolName: "scope",
            baseCost: 120_000,
            costGrowth: 2.3,
            maxLevel: 6,
            effect: .generatorProduction("nebula-mine"),
            effectPerLevel: 0.38
        ),
        UpgradeDefinition(
            id: "fusion-cooling",
            name: "Fusion Cooling",
            detail: "Boosts Fusion Array output",
            symbolName: "snowflake",
            baseCost: 880_000,
            costGrowth: 2.34,
            maxLevel: 6,
            effect: .generatorProduction("fusion-array"),
            effectPerLevel: 0.42
        ),
        UpgradeDefinition(
            id: "prism-charter",
            name: "Prism Charter",
            detail: "Raises all output for long runs",
            symbolName: "diamond.circle.fill",
            baseCost: 2_400_000,
            costGrowth: 2.45,
            maxLevel: 5,
            effect: .globalProduction,
            effectPerLevel: 0.22
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
        ),
        CrewDefinition(
            id: "vesper",
            name: "Vesper",
            role: "Milestone planner",
            rarity: "Epic",
            symbolName: "map.fill",
            bonusPercentage: 0.1
        ),
        CrewDefinition(
            id: "lyra",
            name: "Lyra",
            role: "Prestige navigator",
            rarity: "Mythic",
            symbolName: "paperplane.circle.fill",
            bonusPercentage: 0.16
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
        ),
        GoalDefinition(
            id: "kiln-crew",
            name: "Kiln Crew",
            description: "Own 10 Spark Kilns",
            completeWhen: "player owns at least 10 Spark Kilns",
            metric: .generatorCount("spark-kiln", 10),
            reward: .stardust(600)
        ),
        GoalDefinition(
            id: "bazaar-network",
            name: "Bazaar Network",
            description: "Own 5 Orbital Bazaars",
            completeWhen: "player owns at least 5 Orbital Bazaars",
            metric: .generatorCount("orbital-bazaar", 5),
            reward: .stardust(4_500)
        ),
        GoalDefinition(
            id: "orchard-season",
            name: "Orchard Season",
            description: "Own 3 Quantum Orchards",
            completeWhen: "player owns at least 3 Quantum Orchards",
            metric: .generatorCount("quantum-orchard", 3),
            reward: .crew("vesper")
        ),
        GoalDefinition(
            id: "deep-survey",
            name: "Deep Survey",
            description: "Own 1 Nebula Mine",
            completeWhen: "player owns at least 1 Nebula Mine",
            metric: .generatorCount("nebula-mine", 1),
            reward: .stardust(18_000)
        ),
        GoalDefinition(
            id: "fusion-ignition",
            name: "Fusion Ignition",
            description: "Reach 5.0K stardust/sec",
            completeWhen: "passive income reaches 5000 stardust per second",
            metric: .passiveIncome(5_000),
            reward: .prism(2)
        ),
        GoalDefinition(
            id: "launch-veteran",
            name: "Launch Veteran",
            description: "Reach prestige level 2",
            completeWhen: "player prestige level reaches 2",
            metric: .prestigeLevel(2),
            reward: .crew("lyra")
        ),
        GoalDefinition(
            id: "stellar-engine",
            name: "Stellar Engine",
            description: "Reach 100.0K stardust/sec",
            completeWhen: "passive income reaches 100000 stardust per second",
            metric: .passiveIncome(100_000),
            reward: .prism(5)
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
