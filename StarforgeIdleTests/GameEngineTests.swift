import XCTest
@testable import StarforgeIdle

final class GameEngineTests: XCTestCase {
    func testTapAddsStardustAndLifetimeProgress() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))

        let reward = GameEngine.performTap(state: &state)

        XCTAssertEqual(reward, 1, accuracy: 0.001)
        XCTAssertEqual(state.stardust, 1, accuracy: 0.001)
        XCTAssertEqual(state.totalStardustEarned, 1, accuracy: 0.001)
        XCTAssertEqual(state.lifetimeTaps, 1)
    }

    func testBuyingGeneratorIncreasesPassiveRate() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.stardust = 100
        state.totalStardustEarned = 100
        let generator = try XCTUnwrap(GameBalance.generatorCatalog.first(where: { $0.id == "spark-kiln" }))

        XCTAssertTrue(GameEngine.buyGenerator(generator, state: &state))

        XCTAssertEqual(state.generatorCount(for: "spark-kiln"), 1)
        XCTAssertGreaterThan(GameEngine.passiveRate(for: state), 0)
    }

    func testUpgradeBoostsTapValue() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.stardust = 100
        let upgrade = try XCTUnwrap(GameBalance.upgradeCatalog.first(where: { $0.id == "tap-rig" }))

        XCTAssertTrue(GameEngine.buyUpgrade(upgrade, state: &state))

        XCTAssertGreaterThan(GameEngine.tapValue(for: state), 1)
    }

    func testOfflineEarningsAreCapped() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.setGeneratorCount(1, for: "spark-kiln")

        let reward = GameEngine.applyOfflineEarnings(
            state: &state,
            now: Date(timeIntervalSince1970: 24 * 60 * 60)
        )

        XCTAssertEqual(reward, 0.2 * GameBalance.baseOfflineCap, accuracy: 0.001)
    }

    func testGoalClaimAppliesRewardOnce() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.lifetimeTaps = 10
        let goal = try XCTUnwrap(GameBalance.goalCatalog.first(where: { $0.id == "wake-the-forge" }))

        XCTAssertTrue(GameEngine.claimGoal(goal, state: &state))
        let afterFirstClaim = state.stardust
        XCTAssertFalse(GameEngine.claimGoal(goal, state: &state))
        XCTAssertEqual(state.stardust, afterFirstClaim)
    }

    func testGoalClaimCanUnlockCrew() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.totalStardustEarned = 250
        let goal = try XCTUnwrap(GameBalance.goalCatalog.first(where: { $0.id == "first-glow" }))

        XCTAssertTrue(GameEngine.claimGoal(goal, state: &state))
        XCTAssertTrue(state.crewIDs.contains("nova"))
    }

    func testPrestigeKeepsCrewAndAddsPrisms() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.totalStardustEarned = 400_000
        state.stardust = 20_000
        state.crewIDs = ["nova"]

        let reward = GameEngine.prestige(state: &state, now: Date(timeIntervalSince1970: 10))

        XCTAssertEqual(reward, 2)
        XCTAssertEqual(state.prisms, 2)
        XCTAssertEqual(state.prestigeLevel, 1)
        XCTAssertTrue(state.crewIDs.contains("nova"))
        XCTAssertEqual(state.stardust, 0)
    }

    func testDailyClaimRewardsOncePerDayAndMaintainsStreak() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.setGeneratorCount(1, for: "spark-kiln")
        let calendar = Calendar(identifier: .gregorian)
        let dayOne = Date(timeIntervalSince1970: 24 * 60 * 60)
        let dayTwo = Date(timeIntervalSince1970: 2 * 24 * 60 * 60)

        let firstReward = GameEngine.claimDaily(state: &state, now: dayOne, calendar: calendar)
        let duplicateReward = GameEngine.claimDaily(state: &state, now: dayOne, calendar: calendar)
        let secondReward = GameEngine.claimDaily(state: &state, now: dayTwo, calendar: calendar)

        XCTAssertGreaterThan(firstReward, 0)
        XCTAssertEqual(duplicateReward, 0)
        XCTAssertGreaterThan(secondReward, firstReward)
        XCTAssertEqual(state.dailyStreak, 2)
    }

    func testDailyClaimRejectsClockRollback() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.setGeneratorCount(1, for: "spark-kiln")
        let calendar = Calendar(identifier: .gregorian)
        let dayTwo = Date(timeIntervalSince1970: 2 * 24 * 60 * 60)
        let dayOne = Date(timeIntervalSince1970: 24 * 60 * 60)

        XCTAssertGreaterThan(GameEngine.claimDaily(state: &state, now: dayTwo, calendar: calendar), 0)
        XCTAssertEqual(GameEngine.claimDaily(state: &state, now: dayOne, calendar: calendar), 0)
    }

    func testDailyClaimIsGatedUntilFirstLine() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(GameEngine.claimDaily(state: &state, now: Date(timeIntervalSince1970: 10)), 0)

        state.setGeneratorCount(1, for: "spark-kiln")
        XCTAssertGreaterThan(GameEngine.claimDaily(state: &state, now: Date(timeIntervalSince1970: 10)), 0)
    }

    func testGeneratorMilestonesBoostPassiveRate() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.setGeneratorCount(9, for: "spark-kiln")
        let beforeMilestone = GameEngine.passiveRate(for: state)

        state.setGeneratorCount(10, for: "spark-kiln")
        let afterMilestone = GameEngine.passiveRate(for: state)

        XCTAssertGreaterThan(afterMilestone, beforeMilestone)
        XCTAssertEqual(GameEngine.milestoneBonus(for: 10), 0.25, accuracy: 0.001)
    }

    func testSaveEnvelopeRoundTrip() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 1))
        state.stardust = 900
        state.setGeneratorCount(3, for: "spark-kiln")

        let data = try JSONEncoder().encode(SavedGameEnvelope(state: state))
        let envelope = try JSONDecoder().decode(SavedGameEnvelope.self, from: data)

        XCTAssertEqual(envelope.version, SavedGameEnvelope.currentVersion)
        XCTAssertEqual(envelope.state.stardust, 900, accuracy: 0.001)
        XCTAssertEqual(envelope.state.generatorCount(for: "spark-kiln"), 3)
    }

    func testLegacySaveDecodeFillsNewCatalogEntries() throws {
        let json = """
        {
          "stardust": 42,
          "totalStardustEarned": 42,
          "lifetimeTaps": 4,
          "prisms": 0,
          "prestigeLevel": 0,
          "generators": [{"id": "spark-kiln", "count": 2}],
          "upgrades": [{"id": "tap-rig", "level": 1}],
          "claimedGoalIDs": [],
          "crewIDs": [],
          "lastSavedAt": 0,
          "lastOfflineReward": 0,
          "createdAt": 0
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(GameState.self, from: json)

        XCTAssertEqual(state.saveVersion, 1)
        XCTAssertEqual(state.generatorCount(for: "spark-kiln"), 2)
        XCTAssertEqual(state.upgradeLevel(for: "tap-rig"), 1)
        XCTAssertTrue(GameBalance.generatorCatalog.allSatisfy { definition in
            state.generators.contains { $0.id == definition.id }
        })
        XCTAssertEqual(state.highestStageCleared, 0)
        XCTAssertEqual(state.rpgHeroes.filter(\.isUnlocked).count, 3)
        XCTAssertTrue(state.rpgEquipmentState(for: "spark-saber")?.isOwned == true)
    }

    func testRPGCampaignHasOneHundredStagesAcrossTenSectors() {
        XCTAssertEqual(GameBalance.rpgStageCatalog.count, 100)
        XCTAssertEqual(GameBalance.rpgStageCatalog.first?.number, 1)
        XCTAssertEqual(GameBalance.rpgStageCatalog.last?.number, 100)
        XCTAssertEqual(GameBalance.rpgStageCatalog.filter(\.isBoss).count, 10)
        XCTAssertEqual(GameBalance.rpgStageCatalog.last?.sector, 10)
    }

    func testRPGStageVictoryAppliesRewardsAndUnlocksLoot() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))

        let report = GameEngine.attemptNextRPGStage(state: &state)

        XCTAssertTrue(report.victory)
        XCTAssertEqual(state.highestStageCleared, 1)
        XCTAssertGreaterThan(state.alloy, 0)
        XCTAssertGreaterThan(state.rpgHeroes.reduce(0) { $0 + $1.experience }, 0)
        XCTAssertNotNil(state.lastCombatReport)
    }

    func testRPGBossClearsAwardSectorMedal() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.highestStageCleared = 9
        state.alloy = 100_000
        state.rpgHeroes = state.rpgHeroes.map { hero in
            var upgraded = hero
            if upgraded.isUnlocked {
                upgraded.level = 20
                upgraded.rank = 2
            }
            return upgraded
        }

        let report = GameEngine.attemptNextRPGStage(state: &state)

        XCTAssertTrue(report.victory)
        XCTAssertEqual(state.highestStageCleared, 10)
        XCTAssertEqual(state.sectorMedals, 1)
    }

    func testRPGIdleRewardScalesWithClearedStage() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.highestStageCleared = 12

        let reward = GameEngine.rpgIdleReward(for: state, elapsed: 3600)

        XCTAssertGreaterThan(reward.alloy, 0)
        XCTAssertGreaterThan(reward.heroXP, 0)
        XCTAssertGreaterThan(reward.stardust, 0)
    }

    func testRPGHeroLevelConsumesAlloyAndXP() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        var hero = try XCTUnwrap(state.rpgHero(for: "forge-captain"))
        hero.experience = GameEngine.rpgHeroXPRequirement(hero)
        state.setRPGHero(hero)
        state.alloy = GameEngine.rpgHeroLevelCost(hero)

        XCTAssertTrue(GameEngine.levelRPGHero("forge-captain", state: &state))
        XCTAssertEqual(state.rpgHero(for: "forge-captain")?.level, 2)
        XCTAssertEqual(state.alloy, 0, accuracy: 0.001)
    }

    func testRPGEquipmentCanBeEquippedAndUpgraded() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        let equipment = try XCTUnwrap(state.rpgEquipmentState(for: "spark-saber"))
        state.alloy = GameEngine.rpgEquipmentUpgradeCost(equipment)

        XCTAssertTrue(GameEngine.equipRPGEquipment("spark-saber", to: "ion-ranger", state: &state))
        XCTAssertEqual(state.equippedItemID(heroID: "ion-ranger", slot: .weapon), "spark-saber")
        XCTAssertTrue(GameEngine.upgradeRPGEquipment("spark-saber", state: &state))
        XCTAssertEqual(state.rpgEquipmentState(for: "spark-saber")?.level, 2)
    }

    func testRPGEquipmentCannotBeDuplicatedAcrossHeroes() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))

        XCTAssertTrue(GameEngine.equipRPGEquipment("spark-saber", to: "forge-captain", state: &state))
        XCTAssertTrue(GameEngine.equipRPGEquipment("spark-saber", to: "ion-ranger", state: &state))

        XCTAssertNil(state.equippedItemID(heroID: "forge-captain", slot: .weapon))
        XCTAssertEqual(state.equippedItemID(heroID: "ion-ranger", slot: .weapon), "spark-saber")
    }

    func testFailedRPGStageDoesNotCreateClickFarmReward() {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.highestStageCleared = 99
        let alloyBefore = state.alloy

        let report = GameEngine.attemptNextRPGStage(state: &state)

        XCTAssertFalse(report.victory)
        XCTAssertEqual(state.highestStageCleared, 99)
        XCTAssertEqual(state.alloy, alloyBefore, accuracy: 0.001)
        XCTAssertTrue(report.reward.isEmpty)
    }

    func testRPGGoalRewardUnlocksEquipment() throws {
        var state = GameState(now: Date(timeIntervalSince1970: 0))
        state.highestStageCleared = 10
        let goal = try XCTUnwrap(GameBalance.goalCatalog.first(where: { $0.id == "first-boss" }))

        XCTAssertFalse(state.rpgEquipmentState(for: "gravity-core")?.isOwned == true)
        XCTAssertTrue(GameEngine.claimGoal(goal, state: &state))
        XCTAssertTrue(state.rpgEquipmentState(for: "gravity-core")?.isOwned == true)
    }

    func testMalformedRPGLoadoutsAreSanitizedOnDecode() throws {
        let json = """
        {
          "saveVersion": 3,
          "stardust": 0,
          "totalStardustEarned": 0,
          "lifetimeTaps": 0,
          "prisms": 0,
          "prestigeLevel": 0,
          "generators": [],
          "upgrades": [],
          "claimedGoalIDs": [],
          "crewIDs": [],
          "lastSavedAt": 0,
          "lastOfflineReward": 0,
          "createdAt": 0,
          "alloy": 0,
          "relicDust": 0,
          "sectorMedals": 0,
          "highestStageCleared": 0,
          "rpgHeroes": [],
          "rpgEquipment": [],
          "rpgLoadouts": [
            {"heroID": "forge-captain", "slot": "weapon", "itemID": "spark-saber"},
            {"heroID": "ion-ranger", "slot": "weapon", "itemID": "spark-saber"},
            {"heroID": "unknown-hero", "slot": "weapon", "itemID": "spark-saber"},
            {"heroID": "medtech", "slot": "armor", "itemID": "plasma-rifle"}
          ],
          "activeHeroIDs": ["forge-captain", "ion-ranger", "medtech"],
          "lastRPGIdleReward": {"alloy":0,"heroXP":0,"relicDust":0,"stardust":0,"sectorMedals":0,"itemIDs":[]}
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(GameState.self, from: json)
        let equippedSparkSabers = state.rpgLoadouts.filter { $0.itemID == "spark-saber" }

        XCTAssertEqual(equippedSparkSabers.count, 1)
        XCTAssertFalse(state.rpgLoadouts.contains { $0.heroID == "unknown-hero" })
        XCTAssertNil(state.equippedItemID(heroID: "medtech", slot: .armor))
    }
}
