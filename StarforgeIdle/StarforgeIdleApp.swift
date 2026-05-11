import SwiftUI

@main
struct StarforgeIdleApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}

