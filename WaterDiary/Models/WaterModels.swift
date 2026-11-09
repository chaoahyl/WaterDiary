import Foundation

struct WaterEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var amount: Int
    var date: Date
}

struct WaterArchive: Codable {
    var dailyGoal = 2000
    var cupAmount = 250
    var entries: [WaterEntry] = []
    // Store a goal per calendar date so later changes preserve historical progress.
    var dailyGoals: [String: Int] = [:]
}

struct WaterDay: Identifiable {
    let date: Date
    let amount: Int
    let goal: Int
    let count: Int

    var id: Date { date }
    var progress: Double { min(Double(amount) / Double(goal), 1) }
    var isComplete: Bool { amount >= goal }
}
