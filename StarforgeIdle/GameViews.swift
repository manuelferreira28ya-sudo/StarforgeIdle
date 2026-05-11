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

struct RPGView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.spaceBlack, .forgeBlue.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        SummaryHeader(state: store.state)
                        RPGResourceStrip(state: store.state)
                        RPGCampaignPanel(state: store.state) {
                            store.fightNextRPGStage()
                        }

                        if let report = store.state.lastCombatReport {
                            CombatReportPanel(report: report)
                        }

                        RPGHeroSection(store: store)
                        CrewCollectionSection(state: store.state)
                        RPGEquipmentSection(store: store)
                        EnemySectorSection()
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Void Frontier")
        }
    }
}

struct CrewCollectionSection: View {
    let state: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Crew Collection", symbolName: "person.crop.circle.badge.checkmark")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 12)], spacing: 12) {
                ForEach(GameBalance.crewCatalog) { crew in
                    CrewCard(crew: crew, isUnlocked: state.crewIDs.contains(crew.id))
                }
            }
        }
    }
}

struct RPGResourceStrip: View {
    let state: GameState

    var body: some View {
        HStack(spacing: 10) {
            StatPill(title: "alloy", value: state.alloy.compactGameValue, symbolName: "hexagon.fill")
            StatPill(title: "dust", value: state.relicDust.compactGameValue, symbolName: "sparkles")
            StatPill(title: "medals", value: "\(state.sectorMedals)", symbolName: "medal.fill")
        }
        .gamePanel()
    }
}

struct RPGCampaignPanel: View {
    let state: GameState
    let fightAction: () -> Void

    var body: some View {
        let nextStage = GameEngine.nextRPGStage(for: state)
        let progress = Double(state.highestStageCleared) / Double(GameBalance.maxRPGStage)
        let squadPower = GameEngine.rpgSquadPower(for: state)

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                RPGAssetBadge(assetName: nextStage?.iconAssetName ?? "RPGIconKey", tint: .flareGold)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Void Frontier")
                        .font(.headline.weight(.black))
                    Text("Stage \(state.highestStageCleared) / \(GameBalance.maxRPGStage)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                    Text("Squad \(squadPower.compactGameValue) power")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.ionTeal)
                }

                Spacer()

                Button(action: fightAction) {
                    Text(nextStage == nil ? "Clear" : nextStage?.isBoss == true ? "Boss" : "Fight")
                        .font(.subheadline.weight(.black))
                        .frame(minWidth: 70)
                }
                .buttonStyle(PurchaseButtonStyle(isEnabled: nextStage != nil))
                .disabled(nextStage == nil)
                .accessibilityLabel("Fight next RPG stage")
            }

            ProgressView(value: progress)
                .tint(Color.flareGold)

            if let nextStage {
                HStack(spacing: 10) {
                    StageStatPill(title: nextStage.enemyName, value: nextStage.enemyPower.compactGameValue, assetName: nextStage.iconAssetName)
                    StageStatPill(title: nextStage.mechanic, value: "S\(nextStage.number)", assetName: nextStage.isBoss ? "RPGIconKey" : "RPGIconBattle")
                }
                Text(GameEngine.rpgRewardDescription(nextStage.reward))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Stage 100 cleared. Frontier Echoes can expand from here.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .gamePanel()
    }
}

struct StageStatPill: View {
    let title: String
    let value: String
    let assetName: String

    var body: some View {
        HStack(spacing: 8) {
            RPGAssetBadge(assetName: assetName, tint: .ionTeal, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.black))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CombatReportPanel: View {
    let report: RPGCombatReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RPGAssetBadge(assetName: report.victory ? "RPGIconChest" : "RPGIconBattle", tint: report.victory ? .flareGold : .cometPink)

                VStack(alignment: .leading, spacing: 5) {
                    Text(report.victory ? "Stage \(report.stage) Cleared" : "Stage \(report.stage) Failed")
                        .font(.headline.weight(.bold))
                    Text(report.enemyName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
            }

            HStack(spacing: 10) {
                StatPill(title: "squad", value: report.squadPower.compactGameValue, symbolName: "person.3.fill")
                StatPill(title: "enemy", value: report.enemyPower.compactGameValue, symbolName: "shield.fill")
            }

            Text(report.advice)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .gamePanel()
    }
}

struct RPGHeroSection: View {
    @ObservedObject var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Squad", symbolName: "person.3.fill")

            ForEach(GameBalance.rpgHeroCatalog) { definition in
                if let hero = store.state.rpgHero(for: definition.id) {
                    RPGHeroRow(definition: definition, hero: hero, state: store.state) {
                        store.toggleActiveRPGHero(hero)
                    } levelAction: {
                        store.levelRPGHero(hero)
                    }
                }
            }
        }
    }
}

struct RPGHeroRow: View {
    let definition: RPGHeroDefinition
    let hero: RPGHeroState
    let state: GameState
    let activeAction: () -> Void
    let levelAction: () -> Void

    var body: some View {
        let isActive = state.activeHeroIDs.contains(hero.id)
        let canLevel = GameEngine.canLevelRPGHero(hero, state: state)
        let xpProgress = min(hero.experience / max(GameEngine.rpgHeroXPRequirement(hero), 1), 1)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RPGAssetBadge(assetName: definition.iconAssetName, tint: hero.isUnlocked ? .flareGold : .white.opacity(0.35))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(definition.name)
                            .font(.headline.weight(.bold))
                        if isActive {
                            Text("Active")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Color.spaceBlack)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 6)
                                .background(Color.ionTeal, in: Capsule())
                        }
                    }
                    Text(hero.isUnlocked ? "\(definition.className) · \(definition.skillName)" : "Unlock at stage \(definition.unlockStage)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                    Text(hero.isUnlocked ? "Power \(GameEngine.rpgPower(for: hero, state: state).compactGameValue) · Rank \(hero.rank)" : definition.role)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.flareGold)
                }

                Spacer()

                Button(action: activeAction) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title3.weight(.black))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(hero.isUnlocked ? Color.ionTeal : Color.white.opacity(0.35))
                .disabled(!hero.isUnlocked)
                .accessibilityLabel(isActive ? "Remove \(definition.name) from active squad" : "Add \(definition.name) to active squad")
            }

            if hero.isUnlocked {
                ProgressView(value: xpProgress)
                    .tint(Color.ionTeal)

                HStack {
                    Text("Level \(hero.level) · XP \(hero.experience.compactGameValue) / \(GameEngine.rpgHeroXPRequirement(hero).compactGameValue)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                    Spacer()
                    Button(action: levelAction) {
                        Text(canLevel ? GameEngine.rpgHeroLevelCost(hero).compactGameValue : "Train")
                            .font(.subheadline.weight(.black))
                            .frame(minWidth: 70)
                    }
                    .buttonStyle(PurchaseButtonStyle(isEnabled: canLevel))
                    .disabled(!canLevel)
                }
            }
        }
        .gamePanel()
        .opacity(hero.isUnlocked ? 1 : 0.54)
    }
}

struct RPGEquipmentSection: View {
    @ObservedObject var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Armory", symbolName: "bag.fill")

            ForEach(GameBalance.rpgEquipmentCatalog) { definition in
                if let equipment = store.state.rpgEquipmentState(for: definition.id) {
                    RPGEquipmentRow(definition: definition, equipment: equipment, state: store.state) {
                        store.upgradeRPGEquipment(equipment)
                    } equipAction: { hero in
                        store.equipRPGEquipment(definition, to: hero)
                    }
                }
            }
        }
    }
}

struct RPGEquipmentRow: View {
    let definition: RPGEquipmentDefinition
    let equipment: RPGEquipmentState
    let state: GameState
    let upgradeAction: () -> Void
    let equipAction: (RPGHeroState) -> Void

    var body: some View {
        let canUpgrade = GameEngine.canUpgradeRPGEquipment(equipment, state: state)
        let availableHeroes = GameEngine.activeRPGHeroStates(for: state)
        let equippedHero = state.rpgLoadouts.first(where: { $0.itemID == equipment.id })?.heroID
        let equippedName = equippedHero.flatMap { id in GameBalance.rpgHeroCatalog.first(where: { $0.id == id })?.name }

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RPGAssetBadge(assetName: definition.iconAssetName, tint: equipment.isOwned ? rarityColor(definition.rarity) : .white.opacity(0.35))

                VStack(alignment: .leading, spacing: 5) {
                    Text(definition.name)
                        .font(.headline.weight(.bold))
                    Text(equipment.isOwned ? "\(definition.slot.title) · \(definition.rarity.title) · L\(equipment.level)" : "Unlock at stage \(definition.unlockStage)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                    Text(equippedName.map { "Equipped: \($0)" } ?? definition.detail)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.flareGold)
                }

                Spacer()

                Menu {
                    ForEach(availableHeroes) { hero in
                        if let heroDefinition = GameBalance.rpgHeroCatalog.first(where: { $0.id == hero.id }) {
                            Button(heroDefinition.name) {
                                equipAction(hero)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title3.weight(.black))
                        .frame(width: 44, height: 44)
                }
                .disabled(!equipment.isOwned)
                .foregroundStyle(equipment.isOwned ? Color.ionTeal : Color.white.opacity(0.35))
            }

            if equipment.isOwned {
                HStack {
                    Text("+\(definition.attackBonus.compactGameValue) atk · +\(definition.hpBonus.compactGameValue) hp · +\(Int(definition.bossBonus * 100))% boss")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                    Spacer()
                    Button(action: upgradeAction) {
                        Text(canUpgrade ? GameEngine.rpgEquipmentUpgradeCost(equipment).compactGameValue : "Upgrade")
                            .font(.subheadline.weight(.black))
                            .frame(minWidth: 78)
                    }
                    .buttonStyle(PurchaseButtonStyle(isEnabled: canUpgrade))
                    .disabled(!canUpgrade)
                }
            }
        }
        .gamePanel()
        .opacity(equipment.isOwned ? 1 : 0.5)
    }

    private func rarityColor(_ rarity: RPGRarity) -> Color {
        switch rarity {
        case .common:
            return .white
        case .uncommon:
            return .ionTeal
        case .rare:
            return .flareGold
        case .epic:
            return .cometPink
        case .prototype:
            return Color(red: 0.75, green: 0.58, blue: 1.0)
        }
    }
}

struct EnemySectorSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Enemy Sectors", symbolName: "map.fill")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 152), spacing: 12)], spacing: 12) {
                ForEach(GameBalance.rpgEnemyFamilies) { family in
                    VStack(alignment: .leading, spacing: 10) {
                        RPGAssetBadge(assetName: family.iconAssetName, tint: .flareGold)
                        Text(family.name)
                            .font(.headline.weight(.bold))
                            .lineLimit(2)
                        Text(family.mechanic)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.66))
                    }
                    .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
                    .gamePanel()
                }
            }
        }
    }
}

struct RPGAssetBadge: View {
    let assetName: String
    let tint: Color
    var size: CGFloat = 44

    var body: some View {
        Image(assetName)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .padding(size * 0.22)
            .frame(width: size, height: size)
            .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.36), lineWidth: 1)
            )
            .accessibilityHidden(true)
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
                .foregroundStyle(Color.flareGold)
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
                .foregroundStyle(Color.ionTeal)
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
                .foregroundStyle(Color.flareGold)
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
                        .foregroundStyle(Color.flareGold)
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
                .tint(canClaim ? Color.ionTeal : Color.flareGold)

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
                        .foregroundStyle(Color.flareGold)
                }

                Text(unlocked ? definition.role : "Unlock at \(definition.unlockAtTotalEarned.compactGameValue) total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))

                Text("+\((definition.baseOutput * Double(max(count, 1))).compactGameValue)/sec base")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.ionTeal)

                if let nextMilestone {
                    Text("Milestone at x\(nextMilestone)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.52))
                } else if count >= GameBalance.milestoneCounts.last ?? 0 {
                    Text("All milestones active")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.flareGold)
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
                .tint(Color.ionTeal)

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
                        .foregroundStyle(Color.flareGold)
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
                .tint(claimed ? Color.ionTeal : Color.flareGold)

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
                    .foregroundStyle(isUnlocked ? Color.ionTeal : Color.white.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(crew.name)
                    .font(.title3.weight(.black))
                Text(crew.role)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                Text("+\(Int(crew.bonusPercentage * 100))% all output")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.flareGold)
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
                .tint(Color.cometPink)

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
