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
        state.lastSavedAt = now
        return reward
    }

    static func applyOfflineEarnings(state: inout GameState, now: Date) -> Double {
        let elapsed = min(max(0, now.timeIntervalSince(state.lastSavedAt)), offlineCap(for: state))
        let reward = passiveRate(for: state) * elapsed
        earn(reward, state: &state)
        state.lastOfflineReward = reward
        state.lastSavedAt = now
        return reward
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
        guard let lastDailyClaimAt = state.lastDailyClaimAt else { return true }
        guard now >= lastDailyClaimAt else { return false }
        return !calendar.isDate(lastDailyClaimAt, inSameDayAs: now)
    }

    static func dailyReward(for state: GameState) -> Double {
        dailyReward(for: state, streak: state.dailyStreak)
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
        GameBalance.upgradeCatalog.reduce(1) { multiplier, upgrade in
            guard case .generatorProduction(let targetID) = upgrade.effect, targetID == generatorID else {
                return multiplier
            }

            return multiplier + Double(state.upgradeLevel(for: upgrade.id)) * upgrade.effectPerLevel
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
