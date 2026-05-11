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
        let calendar = Calendar(identifier: .gregorian)
        let dayTwo = Date(timeIntervalSince1970: 2 * 24 * 60 * 60)
        let dayOne = Date(timeIntervalSince1970: 24 * 60 * 60)

        XCTAssertGreaterThan(GameEngine.claimDaily(state: &state, now: dayTwo, calendar: calendar), 0)
        XCTAssertEqual(GameEngine.claimDaily(state: &state, now: dayOne, calendar: calendar), 0)
    }
}
