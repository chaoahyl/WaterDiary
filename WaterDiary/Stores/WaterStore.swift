import Foundation
import Combine

final class WaterStore: ObservableObject {
    static let amountRange = 1...2000
    static let goalRange = 500...10000
    private static let storageKey = "waterDiary.archive.v1"

    @Published private(set) var archive: WaterArchive
    @Published private(set) var now: Date
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    /// False after the saved archive failed to load; the shown archive is then only a placeholder.
    private(set) var canSave = true
    private var calendar: Calendar { .autoupdatingCurrent }

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        self.now = now
        if let data = defaults.data(forKey: Self.storageKey) {
            do {
                let saved = try JSONDecoder().decode(WaterArchive.self, from: data)
                guard Self.goalRange.contains(saved.dailyGoal),
                      Self.amountRange.contains(saved.cupAmount),
                      saved.entries.allSatisfy({ Self.amountRange.contains($0.amount) }),
                      Set(saved.entries.map(\.id)).count == saved.entries.count,
                      saved.dailyGoals.values.allSatisfy({ Self.goalRange.contains($0) }) else {
                    throw CocoaError(.coderReadCorrupt)
                }
                archive = saved
            } catch {
                archive = WaterArchive()
                canSave = false
                errorMessage = "暂时无法读取本地记录。原始数据已保留，请重新打开应用后重试。"
            }
        } else {
            archive = WaterArchive()
        }
    }

    var today: WaterDay { day(for: now) }
    var todayEntries: [WaterEntry] { entries(on: now) }
    var recordedDays: Int { Set(archive.entries.map { dayKey($0.date) }).count }
    var totalAmount: Int { archive.entries.reduce(0) { $0 + $1.amount } }
    var recentDays: [WaterDay] {
        (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now))
                .map { day(for: $0) }
        }
    }
    var history: [WaterDay] {
        Set(archive.entries.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >).map { day(for: $0) }
    }
    var streak: Int {
        var date = calendar.startOfDay(for: now)
        // Today's unfinished goal leaves yesterday's streak intact until midnight.
        if !day(for: date).isComplete {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        var result = 0
        while day(for: date).isComplete {
            result += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return result
    }

    func refreshDate(_ date: Date = Date()) { now = date }

    func entries(on date: Date) -> [WaterEntry] {
        archive.entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func day(for date: Date) -> WaterDay {
        let records = entries(on: date)
        return WaterDay(date: calendar.startOfDay(for: date),
                        amount: records.reduce(0) { $0 + $1.amount },
                        goal: archive.dailyGoals[dayKey(date)] ?? archive.dailyGoal,
                        count: records.count)
    }

    @discardableResult
    func add(amount: Int, date: Date = Date()) -> Bool {
        guard Self.amountRange.contains(amount), date <= Date() else { return false }
        var updated = archive
        preserveGoal(for: date, in: &updated)
        updated.entries.append(WaterEntry(id: UUID(), amount: amount, date: date))
        return save(updated)
    }

    @discardableResult
    func edit(_ entry: WaterEntry, amount: Int, date: Date) -> Bool {
        guard Self.amountRange.contains(amount), date <= Date(),
              let index = archive.entries.firstIndex(where: { $0.id == entry.id }) else { return false }
        var updated = archive
        preserveGoal(for: date, in: &updated)
        updated.entries[index].amount = amount
        updated.entries[index].date = date
        return save(updated)
    }

    @discardableResult
    func delete(_ entry: WaterEntry) -> Bool {
        var updated = archive
        updated.entries.removeAll { $0.id == entry.id }
        return save(updated)
    }

    @discardableResult
    func setGoal(_ amount: Int) -> Bool {
        guard Self.goalRange.contains(amount) else { return false }
        var updated = archive
        updated.dailyGoal = amount
        updated.dailyGoals[dayKey(Date())] = amount
        return save(updated)
    }

    @discardableResult
    func setCupAmount(_ amount: Int) -> Bool {
        guard Self.amountRange.contains(amount) else { return false }
        var updated = archive
        updated.cupAmount = amount
        return save(updated)
    }

    private func dayKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.era, .year, .month, .day], from: date)
        return "\(parts.era ?? 0)-\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    private func preserveGoal(for date: Date, in updated: inout WaterArchive) {
        let key = dayKey(date)
        if updated.dailyGoals[key] == nil { updated.dailyGoals[key] = updated.dailyGoal }
    }

    private func save(_ updated: WaterArchive) -> Bool {
        guard canSave else {
            errorMessage = "本地记录尚未恢复，暂时不能保存。请重新打开应用后重试。"
            return false
        }
        do {
            let data = try JSONEncoder().encode(updated)
            defaults.set(data, forKey: Self.storageKey)
            archive = updated
            now = Date()
            return true
        } catch {
            errorMessage = "这次记录没有保存成功，请重试。"
            return false
        }
    }
}
