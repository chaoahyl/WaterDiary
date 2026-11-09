import SwiftUI

@main
struct WaterDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }
}
