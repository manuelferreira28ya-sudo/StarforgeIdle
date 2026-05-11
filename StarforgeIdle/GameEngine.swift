import Foundation

enum GameEngine {
    static func tapValue(for state: GameState) -> Double {
        let tapMultiplier = GameBalance.upgradeCatalog.reduce(1) { multiplier, upgrade in
            guard upgrade.effect == .tapValue else { return multiplier }
            return multiplier + Double(state.upgradeLevel(for: upgrade.id)) * upgrade.effectPerLevel
        }

        return tapMultiplier * globalMultiplier(for: state)
    }

    static func passiveRate(for state: GameState) -> Double {
        GameBalance.generatorCatalog.reduce(0) { partial, generator in
            let count = Double(state.generatorCount(for: generator.id))
            let generatorBoost = productionMultiplier(for: generator.id, state: state)
            return partial + generator.baseOutput * count * generatorBoost
        } * globalMultiplier(for: state)
    }

    static func offlineCap(for state: GameState) -> TimeInterval {
        let multiplier = GameBalance.upgradeCatalog.reduce(1) { partial, upgrade in
            guard upgrade.effect == .offlineWindow else { return partial }
            return partial + Double(state.upgradeLevel(for: upgrade.id)) * upgrade.effectPerLevel
        }

        return GameBalance.baseOfflineCap * multiplier
    }

    static func generatorCost(_ definition: GeneratorDefinition, state: GameState) -> Double {
        let count = Double(state.generatorCount(for: definition.id))
        return definition.baseCost * pow(definition.costGrowth, count)
    }

    static func upgradeCost(_ definition: UpgradeDefinition, state: GameState) -> Double? {
        let level = state.upgradeLevel(for: definition.id)
        guard level < definition.maxLevel else { return nil }
        return definition.baseCost * pow(definition.costGrowth, Double(level))
    }

    static func isGeneratorUnlocked(_ definition: GeneratorDefinition, state: GameState) -> Bool {
        state.totalStardustEarned >= definition.unlockAtTotalEarned
    }

    static func canBuyGenerator(_ definition: GeneratorDefinition, state: GameState) -> Bool {
        isGeneratorUnlocked(definition, state: state) && state.stardust >= generatorCost(definition, state: state)
    }

    static func buyGenerator(_ definition: GeneratorDefinition, state: inout GameState) -> Bool {
        let cost = generatorCost(definition, state: state)
        guard isGeneratorUnlocked(definition, state: state), state.stardust >= cost else { return false }
        state.stardust -= cost
        state.setGeneratorCount(state.generatorCount(for: definition.id) + 1, for: definition.id)
        return true
    }

    static func canBuyUpgrade(_ definition: UpgradeDefinition, state: GameState) -> Bool {
        guard let cost = upgradeCost(definition, state: state) else { return false }
        return state.stardust >= cost
    }

    static func buyUpgrade(_ definition: UpgradeDefinition, state: inout GameState) -> Bool {
        guard let cost = upgradeCost(definition, state: state), state.stardust >= cost else { return false }
        state.stardust -= cost
        state.setUpgradeLevel(state.upgradeLevel(for: definition.id) + 1, for: definition.id)
        return true
    }

    static func performTap(state: inout GameState) -> Double {
        let reward = tapValue(for: state)
        earn(reward, state: &state)
        state.lifetimeTaps += 1
        return reward
    }

    static func tick(state: inout GameState, now: Date) -> Double {
        let elapsed = min(max(0, now.timeIntervalSince(state.lastSavedAt)), 5)
        let reward = passiveRate(for: state) * elapsed
        earn(reward, state: &state)
        let rpgReward = rpgIdleReward(for: state, elapsed: elapsed)
        apply(rpgReward, state: &state)
        state.lastRPGIdleReward = rpgReward
        state.lastSavedAt = now
        return reward
    }

    static func applyOfflineEarnings(state: inout GameState, now: Date) -> Double {
        let elapsed = min(max(0, now.timeIntervalSince(state.lastSavedAt)), offlineCap(for: state))
        let reward = passiveRate(for: state) * elapsed
        earn(reward, state: &state)
        let rpgReward = rpgIdleReward(for: state, elapsed: elapsed)
        apply(rpgReward, state: &state)
        state.lastOfflineReward = reward
        state.lastRPGIdleReward = rpgReward
        state.lastSavedAt = now
        return reward
    }

    static func nextRPGStage(for state: GameState) -> RPGStageDefinition? {
        guard state.highestStageCleared < GameBalance.maxRPGStage else { return nil }
        return GameBalance.stageDefinition(for: state.highestStageCleared + 1)
    }

    static func rpgIdleReward(for state: GameState, elapsed: TimeInterval) -> RPGRewardBundle {
        guard elapsed > 0, state.highestStageCleared > 0 else { return .empty }
        let cappedElapsed = min(elapsed, rpgOfflineCap(for: state))
        let stage = GameBalance.stageDefinition(for: max(1, state.highestStageCleared))
        let hourFactor = cappedElapsed / 3600
        let idleMultiplier = 1 + rpgIdleBonus(for: state)
        return RPGRewardBundle(
            alloy: stage.reward.alloy * 0.42 * hourFactor * idleMultiplier,
            heroXP: stage.reward.heroXP * 0.34 * hourFactor * idleMultiplier,
            relicDust: stage.reward.relicDust * 0.18 * hourFactor,
            stardust: stage.reward.stardust * 0.3 * hourFactor,
            sectorMedals: 0,
            itemIDs: []
        )
    }

    static func rpgOfflineCap(for state: GameState) -> TimeInterval {
        let medalBonus = min(Double(state.sectorMedals), 10) * 0.18
        let stageBonus = Double(state.highestStageCleared / 10) * 0.08
        return GameBalance.rpgBaseOfflineCap * (1 + medalBonus + stageBonus)
    }

    static func rpgSquadPower(for state: GameState) -> Double {
        activeRPGHeroStates(for: state).reduce(0) { partial, hero in
            partial + rpgPower(for: hero, state: state)
        }
    }

    static func rpgPower(for hero: RPGHeroState, state: GameState) -> Double {
        guard hero.isUnlocked, let definition = GameBalance.rpgHeroCatalog.first(where: { $0.id == hero.id }) else {
            return 0
        }
        let levelMultiplier = 1 + Double(max(hero.level - 1, 0)) * 0.18
        let rankMultiplier = 1 + Double(max(hero.rank - 1, 0)) * 0.16
        let base = (definition.baseHP * 0.42 + definition.baseAttack * 8.2 + definition.baseArmor * 5.6 + definition.baseSpeed * 52)
            * levelMultiplier
            * rankMultiplier
        return base + equippedPowerBonus(for: hero.id, state: state)
    }

    static func rpgHeroLevelCost(_ hero: RPGHeroState) -> Double {
        80 * pow(1.22, Double(max(hero.level - 1, 0)))
    }

    static func rpgHeroXPRequirement(_ hero: RPGHeroState) -> Double {
        55 * pow(1.18, Double(max(hero.level - 1, 0)))
    }

    static func canLevelRPGHero(_ hero: RPGHeroState, state: GameState) -> Bool {
        hero.isUnlocked && hero.level < 60 && state.alloy >= rpgHeroLevelCost(hero) && hero.experience >= rpgHeroXPRequirement(hero)
    }

    static func levelRPGHero(_ heroID: String, state: inout GameState) -> Bool {
        guard var hero = state.rpgHero(for: heroID), canLevelRPGHero(hero, state: state) else { return false }
        state.alloy -= rpgHeroLevelCost(hero)
        hero.experience -= rpgHeroXPRequirement(hero)
        hero.level += 1
        hero.rank = max(hero.rank, min(4, 1 + hero.level / 15))
        state.setRPGHero(hero)
        return true
    }

    static func rpgEquipmentUpgradeCost(_ equipment: RPGEquipmentState) -> Double {
        120 * pow(1.28, Double(max(equipment.level - 1, 0)))
    }

    static func canUpgradeRPGEquipment(_ equipment: RPGEquipmentState, state: GameState) -> Bool {
        equipment.isOwned && equipment.level < 25 && state.alloy >= rpgEquipmentUpgradeCost(equipment)
    }

    static func upgradeRPGEquipment(_ equipmentID: String, state: inout GameState) -> Bool {
        guard var equipment = state.rpgEquipmentState(for: equipmentID), canUpgradeRPGEquipment(equipment, state: state) else {
            return false
        }
        state.alloy -= rpgEquipmentUpgradeCost(equipment)
        equipment.level += 1
        state.setRPGEquipment(equipment)
        return true
    }

    static func equipRPGEquipment(_ equipmentID: String, to heroID: String, state: inout GameState) -> Bool {
        guard let equipmentState = state.rpgEquipmentState(for: equipmentID), equipmentState.isOwned,
              let equipment = GameBalance.rpgEquipmentCatalog.first(where: { $0.id == equipmentID }),
              let hero = state.rpgHero(for: heroID), hero.isUnlocked else {
            return false
        }
        state.setEquippedItemID(equipmentID, heroID: heroID, slot: equipment.slot)
        return true
    }

    static func setActiveRPGHeroes(_ heroIDs: [String], state: inout GameState) -> Bool {
        let unlocked = Set(state.rpgHeroes.filter(\.isUnlocked).map(\.id))
        let valid = heroIDs.filter { unlocked.contains($0) }
        guard !valid.isEmpty else { return false }
        state.activeHeroIDs = Array(valid.prefix(3))
        return true
    }

    static func attemptNextRPGStage(state: inout GameState) -> RPGCombatReport {
        guard let stage = nextRPGStage(for: state) else {
            let report = RPGCombatReport(
                stage: GameBalance.maxRPGStage,
                enemyName: "Frontier Echo",
                mechanic: "repeatable echoes",
                victory: false,
                squadPower: rpgSquadPower(for: state),
                enemyPower: 0,
                remainingHPPercent: 1,
                reward: .empty,
                advice: "Stage 100 is clear. Future updates can add repeatable Frontier Echoes."
            )
            state.lastCombatReport = report
            return report
        }

        let squadPower = rpgSquadPower(for: state)
        let bossBonus = stage.isBoss ? totalBossBonus(for: state) : 0
        let effectivePower = squadPower * (1 + bossBonus)
        let victory = effectivePower >= stage.enemyPower * 0.94
        let remainingHP = victory ? min(0.96, max(0.08, (effectivePower - stage.enemyPower * 0.62) / max(effectivePower, 1))) : 0
        let reward = victory ? stage.reward : failedStageReward(for: stage)

        if victory {
            state.highestStageCleared = max(state.highestStageCleared, stage.number)
        }
        apply(reward, state: &state)
        unlockRPGProgression(state: &state)

        let report = RPGCombatReport(
            stage: stage.number,
            enemyName: stage.enemyName,
            mechanic: stage.mechanic,
            victory: victory,
            squadPower: effectivePower,
            enemyPower: stage.enemyPower,
            remainingHPPercent: remainingHP,
            reward: reward,
            advice: victory ? victoryAdvice(for: stage, state: state) : failureAdvice(for: stage)
        )
        state.lastCombatReport = report
        return report
    }

    static func activeRPGHeroStates(for state: GameState) -> [RPGHeroState] {
        let active = state.activeHeroIDs.compactMap { id in
            state.rpgHero(for: id)
        }.filter(\.isUnlocked)

        if active.isEmpty {
            return Array(state.rpgHeroes.filter(\.isUnlocked).prefix(3))
        }

        return Array(active.prefix(3))
    }

    static func rpgRewardDescription(_ reward: RPGRewardBundle) -> String {
        var pieces: [String] = []
        if reward.alloy > 0 {
            pieces.append("+\(reward.alloy.compactGameValue) alloy")
        }
        if reward.heroXP > 0 {
            pieces.append("+\(reward.heroXP.compactGameValue) XP")
        }
        if reward.relicDust > 0 {
            pieces.append("+\(reward.relicDust.compactGameValue) dust")
        }
        if reward.stardust > 0 {
            pieces.append("+\(reward.stardust.compactGameValue) stardust")
        }
        if reward.sectorMedals > 0 {
            pieces.append("+\(reward.sectorMedals) medal")
        }
        if !reward.itemIDs.isEmpty {
            let names = reward.itemIDs.compactMap { id in
                GameBalance.rpgEquipmentCatalog.first(where: { $0.id == id })?.name
            }
            pieces.append("loot: \(names.joined(separator: ", "))")
        }
        return pieces.isEmpty ? "No reward" : pieces.joined(separator: " · ")
    }

    static func progress(for goal: GoalDefinition, state: GameState) -> GoalProgress {
        switch goal.metric {
        case .lifetimeTaps(let target):
            return GoalProgress(current: Double(state.lifetimeTaps), target: Double(target))
        case .totalStardust(let target):
            return GoalProgress(current: state.totalStardustEarned, target: target)
        case .generatorCount(let id, let target):
            return GoalProgress(current: Double(state.generatorCount(for: id)), target: Double(target))
        case .upgradeLevels(let target):
            let levels = state.upgrades.reduce(0) { $0 + $1.level }
            return GoalProgress(current: Double(levels), target: Double(target))
        case .passiveIncome(let target):
            return GoalProgress(current: passiveRate(for: state), target: target)
        case .crewUnlocked(let target):
            return GoalProgress(current: Double(state.crewIDs.count), target: Double(target))
        case .prisms(let target):
            return GoalProgress(current: Double(state.prisms), target: Double(target))
        case .prestigeLevel(let target):
            return GoalProgress(current: Double(state.prestigeLevel), target: Double(target))
        case .rpgStage(let target):
            return GoalProgress(current: Double(state.highestStageCleared), target: Double(target))
        case .rpgHeroesUnlocked(let target):
            return GoalProgress(current: Double(state.unlockedRPGHeroCount), target: Double(target))
        case .rpgEquipmentOwned(let target):
            return GoalProgress(current: Double(state.ownedRPGEquipmentCount), target: Double(target))
        case .sectorMedals(let target):
            return GoalProgress(current: Double(state.sectorMedals), target: Double(target))
        }
    }

    static func canClaimGoal(_ goal: GoalDefinition, state: GameState) -> Bool {
        !state.claimedGoalIDs.contains(goal.id) && progress(for: goal, state: state).isComplete
    }

    static func claimGoal(_ goal: GoalDefinition, state: inout GameState) -> Bool {
        guard canClaimGoal(goal, state: state) else { return false }
        state.claimedGoalIDs.insert(goal.id)
        apply(goal.reward, state: &state)
        return true
    }

    static func prestigeReward(for state: GameState) -> Int {
        guard state.totalStardustEarned >= GameBalance.prestigeThreshold else { return 0 }
        return max(1, Int(sqrt(state.totalStardustEarned / GameBalance.prestigeThreshold)))
    }

    static func canPrestige(_ state: GameState) -> Bool {
        prestigeReward(for: state) > 0
    }

    static func prestige(state: inout GameState, now: Date = Date()) -> Int {
        let reward = prestigeReward(for: state)
        guard reward > 0 else { return 0 }

        let keptCrew = state.crewIDs
        let keptPrisms = state.prisms + reward
        let nextLevel = state.prestigeLevel + 1

        state = GameState(now: now)
        state.crewIDs = keptCrew
        state.prisms = keptPrisms
        state.prestigeLevel = nextLevel
        return reward
    }

    static func canClaimDaily(state: GameState, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard hasUnlockedDailySupply(state) else { return false }
        guard let lastDailyClaimAt = state.lastDailyClaimAt else { return true }
        guard now >= lastDailyClaimAt else { return false }
        return !calendar.isDate(lastDailyClaimAt, inSameDayAs: now)
    }

    static func dailyReward(for state: GameState) -> Double {
        dailyReward(for: state, streak: state.dailyStreak)
    }

    static func hasUnlockedDailySupply(_ state: GameState) -> Bool {
        state.generators.contains { $0.count > 0 } || state.claimedGoalIDs.contains("wake-the-forge")
    }

    static func nextDailyReward(for state: GameState, now: Date = Date(), calendar: Calendar = .current) -> Double {
        dailyReward(for: state, streak: nextDailyStreak(for: state, now: now, calendar: calendar))
    }

    private static func dailyReward(for state: GameState, streak: Int) -> Double {
        let streakMultiplier = 1 + min(Double(max(streak, 1) - 1), 6) * 0.2
        let passiveFloor = max(passiveRate(for: state) * 90, GameBalance.dailyBaseReward)
        return passiveFloor * streakMultiplier
    }

    static func claimDaily(state: inout GameState, now: Date = Date(), calendar: Calendar = .current) -> Double {
        guard canClaimDaily(state: state, now: now, calendar: calendar) else { return 0 }

        let nextStreak = nextDailyStreak(for: state, now: now, calendar: calendar)
        let reward = dailyReward(for: state, streak: nextStreak)
        state.dailyStreak = nextStreak
        earn(reward, state: &state)
        state.lastDailyClaimAt = now
        return reward
    }

    private static func nextDailyStreak(for state: GameState, now: Date, calendar: Calendar) -> Int {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        if let lastDailyClaimAt = state.lastDailyClaimAt, calendar.isDate(lastDailyClaimAt, inSameDayAs: yesterday) {
            return state.dailyStreak + 1
        }

        return 1
    }

    static func rewardDescription(_ reward: GoalReward) -> String {
        switch reward {
        case .stardust(let amount):
            return "+\(amount.compactGameValue) stardust"
        case .prism(let amount):
            return "+\(amount) prism"
        case .crew(let id):
            let crew = GameBalance.crewCatalog.first(where: { $0.id == id })
            return crew.map { "Crew: \($0.name)" } ?? "Crew card"
        case .alloy(let amount):
            return "+\(amount.compactGameValue) alloy"
        case .relicDust(let amount):
            return "+\(amount.compactGameValue) relic dust"
        case .rpgEquipment(let id):
            let equipment = GameBalance.rpgEquipmentCatalog.first(where: { $0.id == id })
            return equipment.map { "Item: \($0.name)" } ?? "RPG item"
        case .rpgHero(let id):
            let hero = GameBalance.rpgHeroCatalog.first(where: { $0.id == id })
            return hero.map { "Hero: \($0.name)" } ?? "RPG hero"
        case .sectorMedal(let amount):
            return "+\(amount) sector medal"
        }
    }

    private static func earn(_ amount: Double, state: inout GameState) {
        guard amount > 0 else { return }
        state.stardust += amount
        state.totalStardustEarned += amount
    }

    private static func apply(_ reward: GoalReward, state: inout GameState) {
        switch reward {
        case .stardust(let amount):
            earn(amount, state: &state)
        case .prism(let amount):
            state.prisms += amount
        case .crew(let id):
            state.crewIDs.insert(id)
        case .alloy(let amount):
            state.alloy += amount
        case .relicDust(let amount):
            state.relicDust += amount
        case .rpgEquipment(let id):
            unlockRPGEquipment(id, state: &state)
        case .rpgHero(let id):
            unlockRPGHero(id, state: &state)
        case .sectorMedal(let amount):
            state.sectorMedals += amount
        }
    }

    private static func apply(_ reward: RPGRewardBundle, state: inout GameState) {
        guard !reward.isEmpty else { return }
        state.alloy += reward.alloy
        state.relicDust += reward.relicDust
        state.sectorMedals += reward.sectorMedals
        earn(reward.stardust, state: &state)

        let activeHeroes = activeRPGHeroStates(for: state)
        if reward.heroXP > 0, !activeHeroes.isEmpty {
            let splitXP = reward.heroXP / Double(activeHeroes.count)
            for hero in activeHeroes {
                var updated = hero
                updated.experience += splitXP
                state.setRPGHero(updated)
            }
        }

        for itemID in reward.itemIDs {
            unlockRPGEquipment(itemID, state: &state)
        }
    }

    private static func equippedPowerBonus(for heroID: String, state: GameState) -> Double {
        RPGEquipmentSlot.allCases.reduce(0) { partial, slot in
            guard let itemID = state.equippedItemID(heroID: heroID, slot: slot),
                  let itemState = state.rpgEquipmentState(for: itemID), itemState.isOwned,
                  let definition = GameBalance.rpgEquipmentCatalog.first(where: { $0.id == itemID }) else {
                return partial
            }

            let levelMultiplier = 1 + Double(max(itemState.level - 1, 0)) * 0.2
            let rarityMultiplier = definition.rarity.powerMultiplier
            let statPower = definition.hpBonus * 0.34
                + definition.attackBonus * 7.8
                + definition.armorBonus * 5.4
                + definition.speedBonus * 70
            return partial + statPower * levelMultiplier * rarityMultiplier
        }
    }

    private static func rpgIdleBonus(for state: GameState) -> Double {
        let itemBonus = state.rpgEquipment.reduce(0) { partial, equipmentState in
            guard equipmentState.isOwned,
                  let definition = GameBalance.rpgEquipmentCatalog.first(where: { $0.id == equipmentState.id }) else {
                return partial
            }
            return partial + definition.idleBonus * (1 + Double(max(equipmentState.level - 1, 0)) * 0.08)
        }

        let heroBonus = activeRPGHeroStates(for: state).contains(where: { $0.id == "scrapmancer" }) ? 0.12 : 0
        return itemBonus + heroBonus
    }

    private static func totalBossBonus(for state: GameState) -> Double {
        let itemBonus = state.rpgEquipment.reduce(0) { partial, equipmentState in
            guard equipmentState.isOwned,
                  let definition = GameBalance.rpgEquipmentCatalog.first(where: { $0.id == equipmentState.id }) else {
                return partial
            }
            return partial + definition.bossBonus * (1 + Double(max(equipmentState.level - 1, 0)) * 0.05)
        }

        let rangerBonus = activeRPGHeroStates(for: state).contains(where: { $0.id == "ion-ranger" }) ? 0.1 : 0
        return itemBonus + rangerBonus
    }

    private static func failedStageReward(for stage: RPGStageDefinition) -> RPGRewardBundle {
        .empty
    }

    private static func unlockRPGProgression(state: inout GameState) {
        for hero in GameBalance.rpgHeroCatalog where state.highestStageCleared >= hero.unlockStage {
            unlockRPGHero(hero.id, state: &state)
        }

        for equipment in GameBalance.rpgEquipmentCatalog where equipment.unlockStage == 0 {
            unlockRPGEquipment(equipment.id, state: &state)
        }
    }

    private static func unlockRPGHero(_ id: String, state: inout GameState) {
        guard var hero = state.rpgHero(for: id) else { return }
        hero.isUnlocked = true
        hero.level = max(hero.level, 1)
        hero.rank = max(hero.rank, 1)
        state.setRPGHero(hero)
        if state.activeHeroIDs.count < 3 && !state.activeHeroIDs.contains(id) {
            state.activeHeroIDs.append(id)
        }
    }

    private static func unlockRPGEquipment(_ id: String, state: inout GameState) {
        guard var equipment = state.rpgEquipmentState(for: id) else { return }
        equipment.isOwned = true
        equipment.level = max(equipment.level, 1)
        state.setRPGEquipment(equipment)
    }

    private static func victoryAdvice(for stage: RPGStageDefinition, state: GameState) -> String {
        if stage.number >= GameBalance.maxRPGStage {
            return "Void Throne cleared. Build strength for future Frontier Echoes."
        }
        if stage.isBoss {
            return "Boss down. New sector unlocked and idle rewards improved."
        }
        if let next = nextRPGStage(for: state), next.isBoss {
            return "Boss ahead. Upgrade armor and equip boss-damage items before pushing."
        }
        return "Push again, or farm this stage for alloy and hero XP."
    }

    private static func failureAdvice(for stage: RPGStageDefinition) -> String {
        if stage.isBoss {
            return "Boss wall: level your tank, upgrade a weapon, and equip boss or armor gear."
        }

        switch stage.mechanic {
        case let mechanic where mechanic.contains("shield"):
            return "Shield wall: unlock Grav Monk or equip Gravity Core."
        case let mechanic where mechanic.contains("burn"):
            return "Burn pressure: bring Medtech and upgrade armor."
        case let mechanic where mechanic.contains("burst"):
            return "Burst check: raise HP, armor, and frontline rank."
        default:
            return "Farm your best stage, level heroes, then push again."
        }
    }

    private static func globalMultiplier(for state: GameState) -> Double {
        let globalUpgrade = GameBalance.upgradeCatalog.reduce(0) { partial, upgrade in
            guard upgrade.effect == .globalProduction else { return partial }
            return partial + Double(state.upgradeLevel(for: upgrade.id)) * upgrade.effectPerLevel
        }
        let prismBonus = Double(state.prisms) * 0.08
        let crewBonus = GameBalance.crewCatalog
            .filter { state.crewIDs.contains($0.id) }
            .reduce(0) { $0 + $1.bonusPercentage }

        return 1 + globalUpgrade + prismBonus + crewBonus
    }

    private static func productionMultiplier(for generatorID: String, state: GameState) -> Double {
        let upgradeMultiplier = GameBalance.upgradeCatalog.reduce(1) { multiplier, upgrade in
            guard case .generatorProduction(let targetID) = upgrade.effect, targetID == generatorID else {
                return multiplier
            }

            return multiplier + Double(state.upgradeLevel(for: upgrade.id)) * upgrade.effectPerLevel
        }

        return upgradeMultiplier + milestoneBonus(for: state.generatorCount(for: generatorID))
    }

    static func milestoneBonus(for count: Int) -> Double {
        GameBalance.milestoneCounts.reduce(0) { bonus, milestone in
            count >= milestone ? bonus + milestoneBonusValue(milestone) : bonus
        }
    }

    static func nextMilestone(after count: Int) -> Int? {
        GameBalance.milestoneCounts.first { count < $0 }
    }

    private static func milestoneBonusValue(_ milestone: Int) -> Double {
        switch milestone {
        case 10:
            return 0.25
        case 25:
            return 0.5
        case 50:
            return 1
        case 100:
            return 2
        default:
            return 0
        }
    }
}

extension Double {
    var compactGameValue: String {
        let absolute = abs(self)

        if absolute >= 1_000_000_000 {
            return String(format: "%.1fB", self / 1_000_000_000)
        } else if absolute >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000)
        } else if absolute >= 1_000 {
            return String(format: "%.1fK", self / 1_000)
        } else if absolute >= 100 {
            return String(format: "%.0f", self)
        } else if absolute >= 10 {
            return String(format: "%.1f", self)
        } else {
            return String(format: "%.2f", self)
        }
    }
}
