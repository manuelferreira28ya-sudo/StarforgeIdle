import SwiftUI

struct ContentView: View {
    @ObservedObject var store: GameStore
    @Environment(\.scenePhase) private var scenePhase
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            ForgeView(store: store)
                .tabItem {
                    Label("Forge", systemImage: "flame.fill")
                }

            UpgradesView(store: store)
                .tabItem {
                    Label("Build", systemImage: "hammer.fill")
                }

            GoalsView(store: store)
                .tabItem {
                    Label("Goals", systemImage: "checklist.checked")
                }

            CrewView(store: store)
                .tabItem {
                    Label("Crew", systemImage: "person.3.fill")
                }

            SupplyView(store: store)
                .tabItem {
                    Label("Supply", systemImage: "calendar")
                }
        }
        .tint(Color.ionTeal)
        .preferredColorScheme(.dark)
        .onAppear {
            store.startSession()
        }
        .onReceive(tick) { now in
            store.tick(now: now)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.startSession()
            } else {
                store.saveProgress()
            }
        }
    }
}

#Preview {
    ContentView(store: GameStore(storage: PreviewGameStorage()))
}

struct PreviewGameStorage: GameStorage {
    func load() -> GameState? {
        var state = GameState()
        state.stardust = 4_200
        state.totalStardustEarned = 9_800
        state.lifetimeTaps = 86
        state.prisms = 1
        state.setGeneratorCount(12, for: "spark-kiln")
        state.setGeneratorCount(3, for: "drone-dock")
        state.setUpgradeLevel(2, for: "tap-rig")
        state.crewIDs = ["nova"]
        return state
    }

    func save(_ state: GameState) { }
}
