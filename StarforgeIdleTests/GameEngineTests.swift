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
    }
}
