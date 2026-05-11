import Foundation

struct SavedGameEnvelope: Codable, Equatable {
    static let currentVersion = 3

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
    var alloy: Double
    var relicDust: Double
    var sectorMedals: Int
    var highestStageCleared: Int
    var rpgHeroes: [RPGHeroState]
    var rpgEquipment: [RPGEquipmentState]
    var rpgLoadouts: [RPGEquipmentLoadout]
    var activeHeroIDs: [String]
    var lastRPGIdleReward: RPGRewardBundle
    var lastCombatReport: RPGCombatReport?

    init(now: Date = Date()) {
        saveVersion = 3
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
        alloy = 0
        relicDust = 0
        sectorMedals = 0
        highestStageCleared = 0
        rpgHeroes = GameState.initialRPGHeroes()
        rpgEquipment = GameState.initialRPGEquipment()
        rpgLoadouts = GameState.initialRPGLoadouts()
        activeHeroIDs = GameState.defaultActiveHeroIDs(from: rpgHeroes)
        lastRPGIdleReward = .empty
        lastCombatReport = nil
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
        case alloy
        case relicDust
        case sectorMedals
        case highestStageCleared
        case rpgHeroes
        case rpgEquipment
        case rpgLoadouts
        case activeHeroIDs
        case lastRPGIdleReward
        case lastCombatReport
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
        alloy = try container.decodeIfPresent(Double.self, forKey: .alloy) ?? 0
        relicDust = try container.decodeIfPresent(Double.self, forKey: .relicDust) ?? 0
        sectorMedals = try container.decodeIfPresent(Int.self, forKey: .sectorMedals) ?? 0
        highestStageCleared = try container.decodeIfPresent(Int.self, forKey: .highestStageCleared) ?? 0
        lastRPGIdleReward = try container.decodeIfPresent(RPGRewardBundle.self, forKey: .lastRPGIdleReward) ?? .empty
        lastCombatReport = try container.decodeIfPresent(RPGCombatReport.self, forKey: .lastCombatReport)

        let savedGenerators = try container.decodeIfPresent([GeneratorState].self, forKey: .generators) ?? []
        let savedUpgrades = try container.decodeIfPresent([UpgradeState].self, forKey: .upgrades) ?? []
        let savedRPGHeroes = try container.decodeIfPresent([RPGHeroState].self, forKey: .rpgHeroes) ?? []
        let savedRPGEquipment = try container.decodeIfPresent([RPGEquipmentState].self, forKey: .rpgEquipment) ?? []
        let savedRPGLoadouts = try container.decodeIfPresent([RPGEquipmentLoadout].self, forKey: .rpgLoadouts) ?? []
        generators = GameState.mergedGenerators(savedGenerators)
        upgrades = GameState.mergedUpgrades(savedUpgrades)
        rpgHeroes = GameState.mergedRPGHeroes(savedRPGHeroes, highestStageCleared: highestStageCleared)
        rpgEquipment = GameState.mergedRPGEquipment(savedRPGEquipment)
        rpgLoadouts = GameState.mergedRPGLoadouts(savedRPGLoadouts)
        activeHeroIDs = try container.decodeIfPresent([String].self, forKey: .activeHeroIDs)
            ?? GameState.defaultActiveHeroIDs(from: rpgHeroes)
        activeHeroIDs = GameState.validActiveHeroIDs(activeHeroIDs, heroes: rpgHeroes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(3, forKey: .saveVersion)
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
        try container.encode(alloy, forKey: .alloy)
        try container.encode(relicDust, forKey: .relicDust)
        try container.encode(sectorMedals, forKey: .sectorMedals)
        try container.encode(highestStageCleared, forKey: .highestStageCleared)
        try container.encode(rpgHeroes, forKey: .rpgHeroes)
        try container.encode(rpgEquipment, forKey: .rpgEquipment)
        try container.encode(rpgLoadouts, forKey: .rpgLoadouts)
        try container.encode(activeHeroIDs, forKey: .activeHeroIDs)
        try container.encode(lastRPGIdleReward, forKey: .lastRPGIdleReward)
        try container.encodeIfPresent(lastCombatReport, forKey: .lastCombatReport)
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

    private static func initialRPGHeroes() -> [RPGHeroState] {
        GameBalance.rpgHeroCatalog.map { definition in
            RPGHeroState(
                id: definition.id,
                level: definition.unlockStage == 0 ? 1 : 0,
                experience: 0,
                rank: definition.unlockStage == 0 ? 1 : 0,
                isUnlocked: definition.unlockStage == 0
            )
        }
    }

    private static func mergedRPGHeroes(_ saved: [RPGHeroState], highestStageCleared: Int) -> [RPGHeroState] {
        GameBalance.rpgHeroCatalog.map { definition in
            var state = saved.first(where: { $0.id == definition.id }) ?? RPGHeroState(
                id: definition.id,
                level: definition.unlockStage == 0 ? 1 : 0,
                experience: 0,
                rank: definition.unlockStage == 0 ? 1 : 0,
                isUnlocked: definition.unlockStage == 0
            )
            if highestStageCleared >= definition.unlockStage {
                state.isUnlocked = true
                state.level = max(state.level, 1)
                state.rank = max(state.rank, 1)
            }
            return state
        }
    }

    private static func initialRPGEquipment() -> [RPGEquipmentState] {
        GameBalance.rpgEquipmentCatalog.map { definition in
            RPGEquipmentState(
                id: definition.id,
                level: definition.unlockStage == 0 ? 1 : 0,
                isOwned: definition.unlockStage == 0
            )
        }
    }

    private static func mergedRPGEquipment(_ saved: [RPGEquipmentState]) -> [RPGEquipmentState] {
        GameBalance.rpgEquipmentCatalog.map { definition in
            var state = saved.first(where: { $0.id == definition.id }) ?? RPGEquipmentState(
                id: definition.id,
                level: definition.unlockStage == 0 ? 1 : 0,
                isOwned: definition.unlockStage == 0
            )
            if definition.unlockStage == 0 {
                state.isOwned = true
                state.level = max(state.level, 1)
            }
            return state
        }
    }

    private static func initialRPGLoadouts() -> [RPGEquipmentLoadout] {
        [
            RPGEquipmentLoadout(heroID: "forge-captain", slot: .weapon, itemID: "spark-saber"),
            RPGEquipmentLoadout(heroID: "forge-captain", slot: .armor, itemID: "reactor-plate"),
            RPGEquipmentLoadout(heroID: "ion-ranger", slot: .weapon, itemID: "plasma-rifle"),
            RPGEquipmentLoadout(heroID: "medtech", slot: .core, itemID: "nano-harness")
        ]
    }

    private static func mergedRPGLoadouts(_ saved: [RPGEquipmentLoadout]) -> [RPGEquipmentLoadout] {
        var merged = initialRPGLoadouts()
        for loadout in saved {
            if let index = merged.firstIndex(where: { $0.heroID == loadout.heroID && $0.slot == loadout.slot }) {
                merged[index] = loadout
            } else {
                merged.append(loadout)
            }
        }
        return sanitizedRPGLoadouts(merged)
    }

    private static func sanitizedRPGLoadouts(_ loadouts: [RPGEquipmentLoadout]) -> [RPGEquipmentLoadout] {
        let validHeroIDs = Set(GameBalance.rpgHeroCatalog.map(\.id))
        let equipmentByID = Dictionary(uniqueKeysWithValues: GameBalance.rpgEquipmentCatalog.map { ($0.id, $0) })
        var usedItemIDs: Set<String> = []
        var sanitized: [RPGEquipmentLoadout] = []

        for loadout in loadouts where validHeroIDs.contains(loadout.heroID) {
            var itemID = loadout.itemID
            if let id = itemID {
                if usedItemIDs.contains(id) || equipmentByID[id]?.slot != loadout.slot {
                    itemID = nil
                } else {
                    usedItemIDs.insert(id)
                }
            }

            if let index = sanitized.firstIndex(where: { $0.heroID == loadout.heroID && $0.slot == loadout.slot }) {
                sanitized[index].itemID = itemID
            } else {
                sanitized.append(RPGEquipmentLoadout(heroID: loadout.heroID, slot: loadout.slot, itemID: itemID))
            }
        }

        return sanitized
    }

    private static func defaultActiveHeroIDs(from heroes: [RPGHeroState]) -> [String] {
        heroes.filter(\.isUnlocked).prefix(3).map(\.id)
    }

    private static func validActiveHeroIDs(_ ids: [String], heroes: [RPGHeroState]) -> [String] {
        let unlockedIDs = Set(heroes.filter(\.isUnlocked).map(\.id))
        let valid = ids.filter { unlockedIDs.contains($0) }
        if valid.isEmpty {
            return defaultActiveHeroIDs(from: heroes)
        }
        return Array(valid.prefix(3))
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

struct RPGHeroState: Identifiable, Codable, Equatable {
    let id: String
    var level: Int
    var experience: Double
    var rank: Int
    var isUnlocked: Bool
}

struct RPGEquipmentState: Identifiable, Codable, Equatable {
    let id: String
    var level: Int
    var isOwned: Bool
}

struct RPGEquipmentLoadout: Identifiable, Codable, Equatable {
    var id: String { "\(heroID)-\(slot.rawValue)" }
    let heroID: String
    let slot: RPGEquipmentSlot
    var itemID: String?
}

struct RPGRewardBundle: Codable, Equatable {
    static let empty = RPGRewardBundle(
        alloy: 0,
        heroXP: 0,
        relicDust: 0,
        stardust: 0,
        sectorMedals: 0,
        itemIDs: []
    )

    let alloy: Double
    let heroXP: Double
    let relicDust: Double
    let stardust: Double
    let sectorMedals: Int
    let itemIDs: [String]

    var isEmpty: Bool {
        alloy <= 0 && heroXP <= 0 && relicDust <= 0 && stardust <= 0 && sectorMedals <= 0 && itemIDs.isEmpty
    }
}

struct RPGCombatReport: Codable, Equatable {
    let stage: Int
    let enemyName: String
    let mechanic: String
    let victory: Bool
    let squadPower: Double
    let enemyPower: Double
    let remainingHPPercent: Double
    let reward: RPGRewardBundle
    let advice: String
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

struct RPGHeroDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let className: String
    let role: String
    let skillName: String
    let passive: String
    let iconAssetName: String
    let unlockStage: Int
    let baseHP: Double
    let baseAttack: Double
    let baseArmor: Double
    let baseSpeed: Double
    let affinity: RPGEquipmentSlot
}

struct RPGEnemyFamilyDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let minionName: String
    let bossName: String
    let mechanic: String
    let iconAssetName: String
    let hpBias: Double
    let attackBias: Double
    let armorBias: Double
}

struct RPGStageDefinition: Identifiable, Codable, Equatable {
    var id: Int { number }
    let number: Int
    let sector: Int
    let name: String
    let enemyName: String
    let mechanic: String
    let iconAssetName: String
    let isBoss: Bool
    let enemyPower: Double
    let reward: RPGRewardBundle
}

struct RPGEquipmentDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let detail: String
    let iconAssetName: String
    let slot: RPGEquipmentSlot
    let rarity: RPGRarity
    let unlockStage: Int
    let hpBonus: Double
    let attackBonus: Double
    let armorBonus: Double
    let speedBonus: Double
    let idleBonus: Double
    let bossBonus: Double
}

enum RPGEquipmentSlot: String, Codable, CaseIterable, Equatable {
    case weapon
    case armor
    case core
    case trinket

    var title: String {
        rawValue.capitalized
    }
}

enum RPGRarity: String, Codable, CaseIterable, Equatable {
    case common
    case uncommon
    case rare
    case epic
    case prototype

    var title: String {
        rawValue.capitalized
    }

    var powerMultiplier: Double {
        switch self {
        case .common:
            return 1
        case .uncommon:
            return 1.18
        case .rare:
            return 1.42
        case .epic:
            return 1.72
        case .prototype:
            return 2.1
        }
    }
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
    case rpgStage(Int)
    case rpgHeroesUnlocked(Int)
    case rpgEquipmentOwned(Int)
    case sectorMedals(Int)
}

enum GoalReward: Codable, Equatable {
    case stardust(Double)
    case prism(Int)
    case crew(String)
    case alloy(Double)
    case relicDust(Double)
    case rpgEquipment(String)
    case rpgHero(String)
    case sectorMedal(Int)
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
    static let maxRPGStage = 100
    static let rpgBaseOfflineCap: TimeInterval = 2 * 60 * 60

    static let rpgHeroCatalog: [RPGHeroDefinition] = [
        RPGHeroDefinition(
            id: "forge-captain",
            name: "Forge Captain",
            className: "Vanguard",
            role: "Frontline armor aura and reliable damage",
            skillName: "Aegis Rally",
            passive: "+8% squad armor while active",
            iconAssetName: "RPGIconShield",
            unlockStage: 0,
            baseHP: 220,
            baseAttack: 26,
            baseArmor: 18,
            baseSpeed: 1.0,
            affinity: .armor
        ),
        RPGHeroDefinition(
            id: "ion-ranger",
            name: "Ion Ranger",
            className: "Striker",
            role: "Backline critical hits and boss execution",
            skillName: "Marked Shot",
            passive: "+10% boss damage while active",
            iconAssetName: "RPGIconBow",
            unlockStage: 0,
            baseHP: 150,
            baseAttack: 40,
            baseArmor: 8,
            baseSpeed: 1.24,
            affinity: .weapon
        ),
        RPGHeroDefinition(
            id: "medtech",
            name: "Medtech",
            className: "Support",
            role: "Healing, cleanse, and survival checks",
            skillName: "Nanite Bloom",
            passive: "+10% effective HP while active",
            iconAssetName: "RPGIconPotion",
            unlockStage: 0,
            baseHP: 170,
            baseAttack: 20,
            baseArmor: 10,
            baseSpeed: 1.1,
            affinity: .core
        ),
        RPGHeroDefinition(
            id: "grav-monk",
            name: "Grav Monk",
            className: "Controller",
            role: "Slows dangerous enemies and disrupts shields",
            skillName: "Gravity Bell",
            passive: "+9% control power against shield stages",
            iconAssetName: "RPGIconCosmos",
            unlockStage: 25,
            baseHP: 185,
            baseAttack: 29,
            baseArmor: 13,
            baseSpeed: 1.05,
            affinity: .trinket
        ),
        RPGHeroDefinition(
            id: "scrapmancer",
            name: "Scrapmancer",
            className: "Engineer",
            role: "Drone summons and stronger idle farming",
            skillName: "Drone Bloom",
            passive: "+12% RPG idle alloy while active",
            iconAssetName: "RPGIconRelic",
            unlockStage: 45,
            baseHP: 160,
            baseAttack: 34,
            baseArmor: 11,
            baseSpeed: 1.16,
            affinity: .core
        ),
        RPGHeroDefinition(
            id: "nova-blade",
            name: "Nova Blade",
            className: "Carry",
            role: "Fragile melee finisher with ramping damage",
            skillName: "Starfall Chain",
            passive: "+14% attack after stage 70",
            iconAssetName: "RPGIconSword",
            unlockStage: 65,
            baseHP: 145,
            baseAttack: 54,
            baseArmor: 7,
            baseSpeed: 1.28,
            affinity: .weapon
        )
    ]

    static let rpgEnemyFamilies: [RPGEnemyFamilyDefinition] = [
        RPGEnemyFamilyDefinition(id: "raider", name: "Rust Raiders", minionName: "Raider Skiff", bossName: "Rust Baron", mechanic: "raw damage", iconAssetName: "RPGIconAxe", hpBias: 1.0, attackBias: 1.0, armorBias: 0.9),
        RPGEnemyFamilyDefinition(id: "warden", name: "Ion Wardens", minionName: "Shield Warden", bossName: "Aegis Marshal", mechanic: "barrier shields", iconAssetName: "RPGIconShield", hpBias: 1.12, attackBias: 0.9, armorBias: 1.25),
        RPGEnemyFamilyDefinition(id: "cryo", name: "Cryo Moons", minionName: "Cryo Lurker", bossName: "Frost Regent", mechanic: "slows and armor", iconAssetName: "RPGIconIce", hpBias: 1.16, attackBias: 0.95, armorBias: 1.35),
        RPGEnemyFamilyDefinition(id: "solar", name: "Solar Wreckage", minionName: "Solar Scourge", bossName: "Flare Tyrant", mechanic: "burn pressure", iconAssetName: "RPGIconFire", hpBias: 0.98, attackBias: 1.28, armorBias: 0.92),
        RPGEnemyFamilyDefinition(id: "drone", name: "Drone Graveyard", minionName: "Grave Drone", bossName: "Hive Compiler", mechanic: "summoned adds", iconAssetName: "RPGIconLightning", hpBias: 0.92, attackBias: 1.18, armorBias: 0.86),
        RPGEnemyFamilyDefinition(id: "comet", name: "Black Comet", minionName: "Comet Reaver", bossName: "Umbra Maw", mechanic: "burst damage", iconAssetName: "RPGIconCosmos", hpBias: 1.05, attackBias: 1.35, armorBias: 0.95),
        RPGEnemyFamilyDefinition(id: "null", name: "Null Foundry", minionName: "Null Cultist", bossName: "Silence Engine", mechanic: "debuffs", iconAssetName: "RPGIconRelic", hpBias: 1.08, attackBias: 1.08, armorBias: 1.08),
        RPGEnemyFamilyDefinition(id: "titan", name: "Titan Orbit", minionName: "Titan Guard", bossName: "Orbit Colossus", mechanic: "boss adds", iconAssetName: "RPGIconArmor", hpBias: 1.32, attackBias: 1.02, armorBias: 1.2),
        RPGEnemyFamilyDefinition(id: "rift", name: "Rift Armada", minionName: "Rift Corsair", bossName: "Armada Mind", mechanic: "mixed squads", iconAssetName: "RPGIconBattle", hpBias: 1.16, attackBias: 1.2, armorBias: 1.1),
        RPGEnemyFamilyDefinition(id: "void", name: "Void Throne", minionName: "Throne Shade", bossName: "Void Sovereign", mechanic: "all mechanics", iconAssetName: "RPGIconKey", hpBias: 1.3, attackBias: 1.28, armorBias: 1.24)
    ]

    static let rpgEquipmentCatalog: [RPGEquipmentDefinition] = [
        RPGEquipmentDefinition(id: "spark-saber", name: "Spark Saber", detail: "Reliable starter blade", iconAssetName: "RPGIconSword", slot: .weapon, rarity: .common, unlockStage: 0, hpBonus: 0, attackBonus: 18, armorBonus: 0, speedBonus: 0.02, idleBonus: 0, bossBonus: 0),
        RPGEquipmentDefinition(id: "plasma-rifle", name: "Plasma Rifle", detail: "Crit-friendly ranged weapon", iconAssetName: "RPGIconBow", slot: .weapon, rarity: .common, unlockStage: 0, hpBonus: 0, attackBonus: 22, armorBonus: 0, speedBonus: 0.04, idleBonus: 0, bossBonus: 0.04),
        RPGEquipmentDefinition(id: "reactor-plate", name: "Reactor Plate", detail: "Frontline survival plating", iconAssetName: "RPGIconArmor", slot: .armor, rarity: .common, unlockStage: 0, hpBonus: 65, attackBonus: 0, armorBonus: 10, speedBonus: -0.02, idleBonus: 0, bossBonus: 0),
        RPGEquipmentDefinition(id: "nano-harness", name: "Nano Harness", detail: "Healing and sustain core", iconAssetName: "RPGIconPotion", slot: .core, rarity: .common, unlockStage: 0, hpBonus: 35, attackBonus: 4, armorBonus: 4, speedBonus: 0, idleBonus: 0.02, bossBonus: 0),
        RPGEquipmentDefinition(id: "void-lens", name: "Void Lens", detail: "Skill power amplifier", iconAssetName: "RPGIconCosmos", slot: .trinket, rarity: .uncommon, unlockStage: 8, hpBonus: 18, attackBonus: 16, armorBonus: 0, speedBonus: 0.05, idleBonus: 0.02, bossBonus: 0.04),
        RPGEquipmentDefinition(id: "gravity-core", name: "Gravity Core", detail: "Slows shielded targets", iconAssetName: "RPGIconRelic", slot: .core, rarity: .uncommon, unlockStage: 15, hpBonus: 38, attackBonus: 8, armorBonus: 8, speedBonus: 0.02, idleBonus: 0.03, bossBonus: 0.02),
        RPGEquipmentDefinition(id: "warden-shield", name: "Warden Shield", detail: "Anti-burst armor slab", iconAssetName: "RPGIconShield", slot: .armor, rarity: .uncommon, unlockStage: 20, hpBonus: 88, attackBonus: 0, armorBonus: 18, speedBonus: -0.04, idleBonus: 0, bossBonus: 0.03),
        RPGEquipmentDefinition(id: "ember-axe", name: "Ember Axe", detail: "Burn-stage cleaver", iconAssetName: "RPGIconAxe", slot: .weapon, rarity: .rare, unlockStage: 30, hpBonus: 0, attackBonus: 46, armorBonus: 0, speedBonus: -0.01, idleBonus: 0, bossBonus: 0.06),
        RPGEquipmentDefinition(id: "cryo-boots", name: "Cryo Boots", detail: "Speed and slow resistance", iconAssetName: "RPGIconBoots", slot: .trinket, rarity: .rare, unlockStage: 35, hpBonus: 20, attackBonus: 8, armorBonus: 4, speedBonus: 0.16, idleBonus: 0.03, bossBonus: 0.02),
        RPGEquipmentDefinition(id: "scrap-crown", name: "Scrap Crown", detail: "Idle alloy economy piece", iconAssetName: "RPGIconCoins", slot: .trinket, rarity: .rare, unlockStage: 45, hpBonus: 24, attackBonus: 12, armorBonus: 6, speedBonus: 0.04, idleBonus: 0.12, bossBonus: 0),
        RPGEquipmentDefinition(id: "storm-staff", name: "Storm Staff", detail: "Add-clearing skill conduit", iconAssetName: "RPGIconStaff", slot: .weapon, rarity: .epic, unlockStage: 55, hpBonus: 0, attackBonus: 72, armorBonus: 0, speedBonus: 0.08, idleBonus: 0.02, bossBonus: 0.08),
        RPGEquipmentDefinition(id: "starbreaker", name: "Starbreaker", detail: "Boss-killer prototype blade", iconAssetName: "RPGIconSword", slot: .weapon, rarity: .prototype, unlockStage: 80, hpBonus: 40, attackBonus: 118, armorBonus: 8, speedBonus: 0.08, idleBonus: 0, bossBonus: 0.18),
        RPGEquipmentDefinition(id: "raider-helm", name: "Raider Helm", detail: "Early HP and armor", iconAssetName: "RPGIconHelm", slot: .armor, rarity: .common, unlockStage: 4, hpBonus: 44, attackBonus: 0, armorBonus: 6, speedBonus: 0, idleBonus: 0, bossBonus: 0),
        RPGEquipmentDefinition(id: "medic-sigil", name: "Medic Sigil", detail: "Keeps the squad standing", iconAssetName: "RPGIconPotion", slot: .trinket, rarity: .uncommon, unlockStage: 12, hpBonus: 30, attackBonus: 3, armorBonus: 3, speedBonus: 0.04, idleBonus: 0.04, bossBonus: 0.02),
        RPGEquipmentDefinition(id: "icebreaker-pick", name: "Icebreaker Pick", detail: "Anti-armor sidearm", iconAssetName: "RPGIconAxe", slot: .weapon, rarity: .uncommon, unlockStage: 24, hpBonus: 0, attackBonus: 34, armorBonus: 2, speedBonus: 0.01, idleBonus: 0, bossBonus: 0.04),
        RPGEquipmentDefinition(id: "flare-cloak", name: "Flare Cloak", detail: "Burn-stage defense", iconAssetName: "RPGIconFire", slot: .armor, rarity: .rare, unlockStage: 40, hpBonus: 110, attackBonus: 6, armorBonus: 20, speedBonus: 0.02, idleBonus: 0.02, bossBonus: 0.04),
        RPGEquipmentDefinition(id: "hive-key", name: "Hive Key", detail: "Drone-stage farming trinket", iconAssetName: "RPGIconKey", slot: .trinket, rarity: .rare, unlockStage: 50, hpBonus: 30, attackBonus: 18, armorBonus: 4, speedBonus: 0.08, idleBonus: 0.08, bossBonus: 0.03),
        RPGEquipmentDefinition(id: "null-mantle", name: "Null Mantle", detail: "Debuff-resistant armor", iconAssetName: "RPGIconArmor", slot: .armor, rarity: .epic, unlockStage: 70, hpBonus: 170, attackBonus: 10, armorBonus: 32, speedBonus: 0.02, idleBonus: 0.04, bossBonus: 0.08),
        RPGEquipmentDefinition(id: "rift-compass", name: "Rift Compass", detail: "Late-game mixed-stage engine", iconAssetName: "RPGIconCosmos", slot: .core, rarity: .epic, unlockStage: 75, hpBonus: 68, attackBonus: 34, armorBonus: 12, speedBonus: 0.1, idleBonus: 0.08, bossBonus: 0.06),
        RPGEquipmentDefinition(id: "sovereign-core", name: "Sovereign Core", detail: "Stage 100 power check relic", iconAssetName: "RPGIconRelic", slot: .core, rarity: .prototype, unlockStage: 95, hpBonus: 120, attackBonus: 76, armorBonus: 26, speedBonus: 0.1, idleBonus: 0.1, bossBonus: 0.14)
    ]

    static let rpgStageCatalog: [RPGStageDefinition] = (1...maxRPGStage).map { stageDefinition(for: $0) }

    static func stageDefinition(for number: Int) -> RPGStageDefinition {
        let clamped = min(max(number, 1), maxRPGStage)
        let sector = ((clamped - 1) / 10) + 1
        let family = rpgEnemyFamilies[sector - 1]
        let isBoss = clamped % 10 == 0
        let waveInSector = ((clamped - 1) % 10) + 1
        let basePower = 170 * pow(1.086, Double(clamped - 1))
        let familyMultiplier = (family.hpBias + family.attackBias + family.armorBias) / 3
        let bossMultiplier = isBoss ? 1.38 + Double(sector) * 0.035 : 1
        let enemyPower = basePower * familyMultiplier * bossMultiplier
        let itemIDs = rpgEquipmentCatalog
            .filter { $0.unlockStage == clamped }
            .map(\.id)
        let reward = RPGRewardBundle(
            alloy: Double(34 + clamped * 9) * (isBoss ? 2.4 : 1),
            heroXP: Double(22 + clamped * 5) * (isBoss ? 2.0 : 1),
            relicDust: isBoss ? Double(6 + sector * 3) : clamped % 5 == 0 ? Double(sector) : 0,
            stardust: Double(clamped * 18) * (isBoss ? 2.5 : 1),
            sectorMedals: isBoss ? 1 : 0,
            itemIDs: itemIDs
        )

        return RPGStageDefinition(
            number: clamped,
            sector: sector,
            name: isBoss ? "Sector \(sector) Boss" : "Stage \(clamped)",
            enemyName: isBoss ? family.bossName : "\(family.minionName) \(waveInSector)",
            mechanic: family.mechanic,
            iconAssetName: family.iconAssetName,
            isBoss: isBoss,
            enemyPower: enemyPower,
            reward: reward
        )
    }

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
        ),
        GoalDefinition(
            id: "frontier-scout",
            name: "Frontier Scout",
            description: "Clear RPG stage 5",
            completeWhen: "player clears Void Frontier stage 5",
            metric: .rpgStage(5),
            reward: .alloy(220)
        ),
        GoalDefinition(
            id: "first-boss",
            name: "First Boss",
            description: "Defeat the stage 10 boss",
            completeWhen: "player clears Void Frontier stage 10",
            metric: .rpgStage(10),
            reward: .rpgEquipment("gravity-core")
        ),
        GoalDefinition(
            id: "squad-four",
            name: "Fourth Signal",
            description: "Unlock 4 RPG heroes",
            completeWhen: "player unlocks 4 RPG heroes",
            metric: .rpgHeroesUnlocked(4),
            reward: .relicDust(40)
        ),
        GoalDefinition(
            id: "sector-five",
            name: "Drone Graveyard",
            description: "Clear RPG stage 50",
            completeWhen: "player clears Void Frontier stage 50",
            metric: .rpgStage(50),
            reward: .rpgEquipment("storm-staff")
        ),
        GoalDefinition(
            id: "armory-builder",
            name: "Armory Builder",
            description: "Own 10 RPG items",
            completeWhen: "player owns 10 RPG equipment pieces",
            metric: .rpgEquipmentOwned(10),
            reward: .sectorMedal(2)
        ),
        GoalDefinition(
            id: "void-throne",
            name: "Void Throne",
            description: "Clear RPG stage 100",
            completeWhen: "player clears Void Frontier stage 100",
            metric: .rpgStage(100),
            reward: .prism(10)
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

    func rpgHero(for id: String) -> RPGHeroState? {
        rpgHeroes.first(where: { $0.id == id })
    }

    mutating func setRPGHero(_ hero: RPGHeroState) {
        if let index = rpgHeroes.firstIndex(where: { $0.id == hero.id }) {
            rpgHeroes[index] = hero
        } else {
            rpgHeroes.append(hero)
        }
    }

    func rpgEquipmentState(for id: String) -> RPGEquipmentState? {
        rpgEquipment.first(where: { $0.id == id })
    }

    mutating func setRPGEquipment(_ equipment: RPGEquipmentState) {
        if let index = rpgEquipment.firstIndex(where: { $0.id == equipment.id }) {
            rpgEquipment[index] = equipment
        } else {
            rpgEquipment.append(equipment)
        }
    }

    func equippedItemID(heroID: String, slot: RPGEquipmentSlot) -> String? {
        rpgLoadouts.first(where: { $0.heroID == heroID && $0.slot == slot })?.itemID
    }

    mutating func setEquippedItemID(_ itemID: String?, heroID: String, slot: RPGEquipmentSlot) {
        if let itemID {
            for index in rpgLoadouts.indices where rpgLoadouts[index].itemID == itemID && (rpgLoadouts[index].heroID != heroID || rpgLoadouts[index].slot != slot) {
                rpgLoadouts[index].itemID = nil
            }
        }

        if let index = rpgLoadouts.firstIndex(where: { $0.heroID == heroID && $0.slot == slot }) {
            rpgLoadouts[index].itemID = itemID
        } else {
            rpgLoadouts.append(RPGEquipmentLoadout(heroID: heroID, slot: slot, itemID: itemID))
        }
    }

    var ownedRPGEquipmentCount: Int {
        rpgEquipment.filter(\.isOwned).count
    }

    var unlockedRPGHeroCount: Int {
        rpgHeroes.filter(\.isUnlocked).count
    }
}
