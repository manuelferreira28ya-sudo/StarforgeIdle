import SwiftUI

struct ForgeView: View {
    @ObservedObject var store: GameStore
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.spaceBlack, .forgeBlue, .spaceBlack],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        SummaryHeader(state: store.state)

                        if let message = store.bannerMessage {
                            BannerView(message: message, onDismiss: store.dismissBanner)
                        }

                        if let goal = GameBalance.goalCatalog.first(where: { !store.state.claimedGoalIDs.contains($0.id) }) {
                            FeaturedGoalPanel(goal: goal, state: store.state) {
                                store.claimGoal(goal)
                            }
                        }

                        Button {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.58)) {
                                pulse.toggle()
                            }
                            store.tapCore()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.flareGold, .cometPink, .forgeBlue],
                                            center: .center,
                                            startRadius: 12,
                                            endRadius: 128
                                        )
                                    )
                                    .frame(width: pulse ? 222 : 210, height: pulse ? 222 : 210)
                                    .shadow(color: .flareGold.opacity(0.38), radius: 28, x: 0, y: 12)

                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 42, weight: .black))
                                    Text("+\(GameEngine.tapValue(for: store.state).compactGameValue)")
                                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                                    Text("per tap")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.72))
                                }
                                .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Forge core")
                        .accessibilityValue("\(GameEngine.tapValue(for: store.state).compactGameValue) stardust per tap")

                        VStack(spacing: 12) {
                            SectionHeader(title: "Active Lines", symbolName: "dot.radiowaves.left.and.right")
                            ForEach(GameBalance.generatorCatalog) { generator in
                                GeneratorRow(definition: generator, state: store.state) {
                                    store.buyGenerator(generator)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Starforge")
        }
    }
}

struct UpgradesView: View {
    @ObservedObject var store: GameStore
    @State private var prestigeOffer: PrestigeOffer?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.spaceBlack, .forgeBlue.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        SummaryHeader(state: store.state)
                        PrestigePanel(state: store.state) {
                            let reward = GameEngine.prestigeReward(for: store.state)
                            if reward > 0 {
                                prestigeOffer = PrestigeOffer(reward: reward)
                            }
                        }

                        SectionHeader(title: "Boosters", symbolName: "bolt.fill")
                        ForEach(GameBalance.upgradeCatalog) { upgrade in
                            UpgradeRow(definition: upgrade, state: store.state) {
                                store.buyUpgrade(upgrade)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Build")
            .sheet(item: $prestigeOffer) { offer in
                PrestigeConfirmationView(reward: offer.reward, state: store.state) {
                    store.prestige()
                    prestigeOffer = nil
                }
            }
        }
    }
}

struct GoalsView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.spaceBlack, .forgeBlue.opacity(0.75)], startPoint: .topLeading, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        SummaryHeader(state: store.state)
                        SectionHeader(title: "Quest Chain", symbolName: "target")

                        ForEach(GameBalance.goalCatalog) { goal in
                            GoalRow(goal: goal, state: store.state) {
                                store.claimGoal(goal)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Goals")
        }
    }
}

struct CrewView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.spaceBlack, .forgeBlue.opacity(0.65)], startPoint: .topTrailing, endPoint: .bottomLeading)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        SummaryHeader(state: store.state)
                        SectionHeader(title: "Crew Collection", symbolName: "person.crop.circle.badge.checkmark")

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 12)], spacing: 12) {
                            ForEach(GameBalance.crewCatalog) { crew in
                                CrewCard(crew: crew, isUnlocked: store.state.crewIDs.contains(crew.id))
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Crew")
        }
    }
}

struct SupplyView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.spaceBlack, .forgeBlue.opacity(0.72)], startPoint: .top, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        SummaryHeader(state: store.state)

                        DailyRewardPanel(state: store.state) {
                            store.claimDaily()
                        }

                        OfflineSummaryPanel(state: store.state)

                        AboutPanel()
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Supply")
        }
    }
}

enum AppLinks {
    static let privacyPolicy = URL(string: "https://github.com/manuelferreira28ya-sudo/StarforgeIdle/blob/main/docs/privacy.md") ?? URL(fileURLWithPath: "/")
    static let support = URL(string: "https://github.com/manuelferreira28ya-sudo/StarforgeIdle/blob/main/docs/support.md") ?? URL(fileURLWithPath: "/")
}

struct SummaryHeader: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.stardust.compactGameValue)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.7)
                    Text("stardust")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label("\(state.prisms)", systemImage: "diamond.fill")
                    Text("prisms")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.flareGold)
            }

            HStack(spacing: 10) {
                StatPill(title: "per sec", value: GameEngine.passiveRate(for: state).compactGameValue, symbolName: "speedometer")
                StatPill(title: "taps", value: "\(state.lifetimeTaps)", symbolName: "hand.tap.fill")
                StatPill(title: "level", value: "\(state.prestigeLevel)", symbolName: "arrow.up.forward.circle.fill")
            }
        }
        .gamePanel()
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundStyle(.ionTeal)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct BannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray.full.fill")
                .foregroundStyle(.flareGold)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.black))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct DailyRewardPanel: View {
    let state: GameState
    let action: () -> Void

    var body: some View {
        let unlocked = GameEngine.hasUnlockedDailySupply(state)
        let canClaim = GameEngine.canClaimDaily(state: state)
        let reward = canClaim ? GameEngine.nextDailyReward(for: state) : GameEngine.dailyReward(for: state)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SymbolBadge(symbolName: "calendar.badge.checkmark", color: .flareGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Supply")
                        .font(.headline.weight(.bold))
                    Text(unlocked ? "Streak \(state.dailyStreak) - \(reward.compactGameValue) stardust" : "Unlock after your first line")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Button(action: action) {
                    Text(canClaim ? "Claim" : unlocked ? "Done" : "Locked")
                        .font(.subheadline.weight(.black))
                        .frame(minWidth: 70)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: canClaim))
                .disabled(!canClaim)
                .accessibilityLabel("Claim daily supply")
            }

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { day in
                    Capsule()
                        .fill(day < min(state.dailyStreak, 7) ? Color.flareGold : Color.white.opacity(0.14))
                        .frame(height: 8)
                }
            }
        }
        .gamePanel()
    }
}

struct OfflineSummaryPanel: View {
    let state: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SymbolBadge(symbolName: "moon.stars.fill", color: .ionTeal)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Offline Window")
                        .font(.headline.weight(.bold))
                    Text("Earn for up to \((GameEngine.offlineCap(for: state) / 3600).compactGameValue) hours away")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
            }

            HStack(spacing: 10) {
                StatPill(title: "last haul", value: state.lastOfflineReward.compactGameValue, symbolName: "tray.full.fill")
                StatPill(title: "daily streak", value: "\(state.dailyStreak)", symbolName: "flame.fill")
            }
        }
        .gamePanel()
    }
}

struct AboutPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SymbolBadge(symbolName: "info.circle.fill", color: .ionTeal)

                VStack(alignment: .leading, spacing: 5) {
                    Text("About")
                        .font(.headline.weight(.bold))
                    Text("No ads, no purchases, no tracking, no account required.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Link(destination: AppLinks.privacyPolicy) {
                    Label("Privacy", systemImage: "lock.shield.fill")
                        .font(.subheadline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: true))

                Link(destination: AppLinks.support) {
                    Label("Support", systemImage: "questionmark.circle.fill")
                        .font(.subheadline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: true))
            }
        }
        .gamePanel()
    }
}

struct SectionHeader: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack {
            Label(title, systemImage: symbolName)
                .font(.headline.weight(.bold))
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

struct FeaturedGoalPanel: View {
    let goal: GoalDefinition
    let state: GameState
    let claimAction: () -> Void

    var body: some View {
        let progress = GameEngine.progress(for: goal, state: state)
        let canClaim = GameEngine.canClaimGoal(goal, state: state)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SymbolBadge(symbolName: canClaim ? "checkmark.seal.fill" : "target", color: canClaim ? .ionTeal : .flareGold)

                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.name)
                        .font(.headline.weight(.bold))
                    Text(goal.description)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                    Text(GameEngine.rewardDescription(goal.reward))
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.flareGold)
                }

                Spacer()

                Button(action: claimAction) {
                    Text("Claim")
                        .font(.subheadline.weight(.black))
                        .frame(minWidth: 64)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: canClaim))
                .disabled(!canClaim)
                .accessibilityLabel("Claim featured goal")
            }

            ProgressView(value: progress.fraction)
                .tint(canClaim ? .ionTeal : .flareGold)

            Text("\(progress.current.compactGameValue) / \(progress.target.compactGameValue)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .gamePanel()
    }
}

struct GeneratorRow: View {
    let definition: GeneratorDefinition
    let state: GameState
    let buyAction: () -> Void

    var body: some View {
        let unlocked = GameEngine.isGeneratorUnlocked(definition, state: state)
        let cost = GameEngine.generatorCost(definition, state: state)
        let count = state.generatorCount(for: definition.id)
        let nextMilestone = GameEngine.nextMilestone(after: count)

        HStack(spacing: 14) {
            SymbolBadge(symbolName: definition.symbolName, color: unlocked ? .ionTeal : .white.opacity(0.35))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(definition.name)
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("x\(count)")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.flareGold)
                }

                Text(unlocked ? definition.role : "Unlock at \(definition.unlockAtTotalEarned.compactGameValue) total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))

                Text("+\((definition.baseOutput * Double(max(count, 1))).compactGameValue)/sec base")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.ionTeal)

                if let nextMilestone {
                    Text("Milestone at x\(nextMilestone)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.52))
                } else if count >= GameBalance.milestoneCounts.last ?? 0 {
                    Text("All milestones active")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.flareGold)
                }
            }

            Button(action: buyAction) {
                Text(cost.compactGameValue)
                    .font(.subheadline.weight(.black))
                    .frame(minWidth: 70)
            }
            .buttonStyle(PurchaseButtonStyle(isEnabled: GameEngine.canBuyGenerator(definition, state: state)))
            .disabled(!GameEngine.canBuyGenerator(definition, state: state))
            .accessibilityLabel("Buy \(definition.name)")
        }
        .gamePanel()
        .opacity(unlocked ? 1 : 0.58)
    }
}

struct PrestigeOffer: Identifiable {
    let id = UUID()
    let reward: Int
}

struct PrestigeConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let reward: Int
    let state: GameState
    let confirm: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.spaceBlack, .forgeBlue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    SymbolBadge(symbolName: "paperplane.fill", color: .cometPink)

                    Text("Launch this run?")
                        .font(.title2.weight(.black))

                    Text("You will reset stardust, generators, upgrades, goals, and taps. Crew and prisms stay with you.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        StatPill(title: "new prisms", value: "+\(reward)", symbolName: "diamond.fill")
                        StatPill(title: "kept crew", value: "\(state.crewIDs.count)", symbolName: "person.3.fill")
                    }

                    Spacer()

                    Button(action: confirm) {
                        Text("Launch Run")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PurchaseButtonStyle(isEnabled: true))

                    Button {
                        dismiss()
                    } label: {
                        Text("Keep Building")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PurchaseButtonStyle(isEnabled: false))
                }
                .padding(18)
            }
            .navigationTitle("Confirm")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

struct UpgradeRow: View {
    let definition: UpgradeDefinition
    let state: GameState
    let buyAction: () -> Void

    var body: some View {
        let level = state.upgradeLevel(for: definition.id)
        let cost = GameEngine.upgradeCost(definition, state: state)
        let canBuy = GameEngine.canBuyUpgrade(definition, state: state)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SymbolBadge(symbolName: definition.symbolName, color: .flareGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.name)
                        .font(.headline.weight(.bold))
                    Text(definition.detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Button(action: buyAction) {
                    Text(cost?.compactGameValue ?? "Max")
                        .font(.subheadline.weight(.black))
                        .frame(minWidth: 70)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: canBuy))
                .disabled(!canBuy)
                .accessibilityLabel("Upgrade \(definition.name)")
            }

            ProgressView(value: Double(level), total: Double(definition.maxLevel))
                .tint(.ionTeal)

            Text("Level \(level)/\(definition.maxLevel)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .gamePanel()
    }
}

struct GoalRow: View {
    let goal: GoalDefinition
    let state: GameState
    let claimAction: () -> Void

    var body: some View {
        let progress = GameEngine.progress(for: goal, state: state)
        let claimed = state.claimedGoalIDs.contains(goal.id)
        let canClaim = GameEngine.canClaimGoal(goal, state: state)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbolName: claimed ? "checkmark.seal.fill" : "target", color: claimed ? .ionTeal : .flareGold)

                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.name)
                        .font(.headline.weight(.bold))
                    Text(goal.description)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(GameEngine.rewardDescription(goal.reward))
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.flareGold)
                }

                Spacer()

                Button(action: claimAction) {
                    Text(claimed ? "Done" : "Claim")
                        .font(.subheadline.weight(.black))
                        .frame(minWidth: 64)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: canClaim))
                .disabled(!canClaim)
                .accessibilityLabel("Claim \(goal.name)")
            }

            ProgressView(value: progress.fraction)
                .tint(claimed ? .ionTeal : .flareGold)

            Text("\(progress.current.compactGameValue) / \(progress.target.compactGameValue)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .gamePanel()
    }
}

struct CrewCard: View {
    let crew: CrewDefinition
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SymbolBadge(symbolName: crew.symbolName, color: isUnlocked ? .flareGold : .white.opacity(0.34))
                Spacer()
                Text(isUnlocked ? crew.rarity : "Locked")
                    .font(.caption.weight(.black))
                    .foregroundStyle(isUnlocked ? .ionTeal : .white.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(crew.name)
                    .font(.title3.weight(.black))
                Text(crew.role)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                Text("+\(Int(crew.bonusPercentage * 100))% all output")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.flareGold)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .gamePanel()
        .opacity(isUnlocked ? 1 : 0.48)
    }
}

struct PrestigePanel: View {
    let state: GameState
    let action: () -> Void

    var body: some View {
        let reward = GameEngine.prestigeReward(for: state)
        let progress = min(state.totalStardustEarned / GameBalance.prestigeThreshold, 1)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SymbolBadge(symbolName: "paperplane.fill", color: .cometPink)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Launch Run")
                        .font(.headline.weight(.bold))
                    Text("Reset production for permanent prisms")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
                Button(action: action) {
                    Text(reward > 0 ? "+\(reward)" : "Locked")
                        .font(.subheadline.weight(.black))
                        .frame(minWidth: 70)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: reward > 0))
                .disabled(reward == 0)
            }

            ProgressView(value: progress)
                .tint(.cometPink)

            Text("\(state.totalStardustEarned.compactGameValue) / \(GameBalance.prestigeThreshold.compactGameValue)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .gamePanel()
    }
}

struct SymbolBadge: View {
    let symbolName: String
    let color: Color

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 22, weight: .heavy))
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct PurchaseButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 11)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? Color.ionTeal : Color.white.opacity(0.1))
            )
            .foregroundStyle(isEnabled ? Color.spaceBlack : Color.white.opacity(0.45))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
