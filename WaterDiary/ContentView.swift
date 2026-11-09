import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var store = WaterStore()
    @Environment(\.scenePhase) private var scenePhase
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            WaterHomeView(store: store)
                .tabItem { Label("首页", systemImage: "drop.fill") }
            WaterProfileView(store: store)
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(WaterStyle.blue)
        .onReceive(clock) { store.refreshDate($0) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            store.refreshDate()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.refreshDate() }
        }
        .alert("记录提示", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
