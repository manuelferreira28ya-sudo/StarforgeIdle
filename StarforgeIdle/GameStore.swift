import Foundation
import SwiftUI
import UIKit

protocol GameStorage {
    func load() -> GameState?
    func save(_ state: GameState)
}

struct UserDefaultsGameStorage: GameStorage {
    private let key = "starforge-idle-state-v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GameState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(SavedGameEnvelope.self, from: data) {
            return envelope.state
        }

        return try? decoder.decode(GameState.self, from: data)
    }

    func save(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(SavedGameEnvelope(state: state)) else { return }
        defaults.set(data, forKey: key)
    }
}

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: GameState
    @Published var lastTapReward: Double = 0
    @Published var bannerMessage: String?

    private let storage: GameStorage
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    private var lastPassiveSaveAt = Date.distantPast

    init(storage: GameStorage = UserDefaultsGameStorage(), now: Date = Date()) {
        self.storage = storage
        state = storage.load() ?? GameState(now: now)
    }

    func startSession(now: Date = Date()) {
        let reward = GameEngine.applyOfflineEarnings(state: &state, now: now)
        if reward >= 1 {
            bannerMessage = "Offline haul: \(reward.compactGameValue)"
        }
        save()
    }

    func tick(now: Date = Date()) {
        if now.timeIntervalSince(state.lastSavedAt) > 10 {
            let reward = GameEngine.applyOfflineEarnings(state: &state, now: now)
            if reward >= 1 {
                bannerMessage = "Offline haul: \(reward.compactGameValue)"
            }
            save()
        } else {
            _ = GameEngine.tick(state: &state, now: now)
            if now.timeIntervalSince(lastPassiveSaveAt) >= 15 {
                save()
                lastPassiveSaveAt = now
            }
        }
    }

    func tapCore() {
        lastTapReward = GameEngine.performTap(state: &state)
        feedback.impactOccurred(intensity: 0.7)
        save()
    }

    func buyGenerator(_ definition: GeneratorDefinition) {
        guard GameEngine.buyGenerator(definition, state: &state) else { return }
        bannerMessage = "\(definition.name) online"
        save()
    }

    func buyUpgrade(_ definition: UpgradeDefinition) {
        guard GameEngine.buyUpgrade(definition, state: &state) else { return }
        bannerMessage = "\(definition.name) upgraded"
        save()
    }

    func claimGoal(_ goal: GoalDefinition) {
        guard GameEngine.claimGoal(goal, state: &state) else { return }
        bannerMessage = "Goal complete: \(goal.name)"
        save()
    }

    func claimDaily(now: Date = Date()) {
        let reward = GameEngine.claimDaily(state: &state, now: now)
        guard reward > 0 else { return }
        bannerMessage = "Daily supply: \(reward.compactGameValue)"
        save()
    }

    func prestige(now: Date = Date()) {
        let reward = GameEngine.prestige(state: &state, now: now)
        guard reward > 0 else { return }
        bannerMessage = "Launch complete: +\(reward) prism"
        save()
    }

    func dismissBanner() {
        bannerMessage = nil
    }

    func saveProgress() {
        save()
    }

    private func save() {
        storage.save(state)
    }
}
