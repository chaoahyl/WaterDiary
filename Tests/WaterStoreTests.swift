// Run with run_model_tests.py; this file is not part of the iOS app target.

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ description: String) {
    guard condition() else { fatalError("FAIL: \(description)") }
    checks += 1
    print("PASS: \(description)")
}

let suiteName = "WaterDiary.tests.\(UUID().uuidString)"
let preferences = UserDefaults(suiteName: suiteName)!
defer { preferences.removePersistentDomain(forName: suiteName) }
let store = WaterStore(defaults: preferences)
let calendar = Calendar.autoupdatingCurrent
let current = Date()
let yesterday = calendar.date(byAdding: .day, value: -1, to: current)!
let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: current)!
let tomorrow = calendar.date(byAdding: .day, value: 1, to: current)!

check(store.today.amount == 0 && store.today.count == 0, "new diary is empty")
check(store.archive.dailyGoal == 2000 && store.archive.cupAmount == 250, "default preferences")
check(store.recentDays.count == 7 && store.recentDays.last?.date == store.today.date, "seven days end today")
check(!store.add(amount: 0) && !store.add(amount: -1) && !store.add(amount: 2001), "invalid amounts rejected")
check(!store.add(amount: 250, date: tomorrow), "future records rejected")
check(store.add(amount: 250) && store.add(amount: 350), "record two drinks")
check(store.today.amount == 600 && store.today.count == 2, "daily total and count")
check(store.today.progress == 0.3 && !store.today.isComplete, "progress reflects daily target")
check(store.todayEntries.first?.amount == 350, "newest record first")

let first = store.archive.entries[0]
check(store.edit(first, amount: 500, date: first.date), "edit amount")
check(store.today.amount == 850 && store.today.count == 2, "edit updates totals without adding a drink")
check(!store.edit(first, amount: 0, date: first.date), "invalid edit rejected")
check(store.edit(first, amount: 500, date: yesterday), "move a drink to yesterday")
check(store.today.amount == 350 && store.day(for: yesterday).amount == 500, "moving record updates both days")
check(store.setGoal(500), "set today's target")
check(store.day(for: yesterday).goal == 2000, "past target preserved")
check(store.today.goal == 500, "new target applies today")
check(!store.setGoal(0) && !store.setGoal(10001), "invalid targets rejected")
check(store.setCupAmount(500) && !store.setCupAmount(2001), "cup preference validation")

let reloaded = WaterStore(defaults: preferences)
check(reloaded.today.amount == 350 && reloaded.archive.cupAmount == 500, "records and cup survive reload")
check(reloaded.today.goal == 500 && reloaded.day(for: yesterday).goal == 2000, "target snapshots survive reload")
check(store.add(amount: 2000, date: yesterday) && store.add(amount: 500), "reach yesterday and today goals")
check(store.day(for: yesterday).progress == 1 && store.day(for: yesterday).amount == 2500, "over-target totals retained, ring capped")
check(store.streak == 2 && store.recordedDays == 2, "two consecutive successful days")
check(store.totalAmount == 3350, "all-time volume")

store.refreshDate(tomorrow)
check(store.today.amount == 0 && store.todayEntries.isEmpty, "midnight resets today's display")
check(store.streak == 2, "unfinished new day preserves yesterday streak")
check(store.day(for: current).amount == 850, "rollover preserves yesterday records")
store.refreshDate(current)

let latest = store.archive.entries.last!
check(store.delete(latest), "delete drink")
check(store.today.amount == 350 && !store.today.isComplete, "delete recomputes progress")
check(store.streak == 1, "unfinished today keeps yesterday streak")
check(store.setGoal(1500) && store.day(for: yesterday).goal == 2000, "later target changes keep history unchanged")
check(store.add(amount: 250, date: twoDaysAgo), "backdated record accepted")
check(store.history.map(\.date) == store.history.map(\.date).sorted(by: >), "history sorted newest first")
check(store.recordedDays == 3 && store.history.count == 3, "history grouped by calendar date")

// A calendar day is not necessarily 86400 seconds long. Exercise DST rollovers.
let originalZone = NSTimeZone.default
NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
let dstCalendar = Calendar.autoupdatingCurrent
let formatter = ISO8601DateFormatter()
let dstStart = formatter.date(from: "2026-03-08T12:00:00-07:00")!
store.refreshDate(dstStart)
let dates = store.recentDays.map(\.date)
check(Set(dates).count == 7, "DST week contains seven distinct dates")
check(zip(dates, dates.dropFirst()).allSatisfy {
    dstCalendar.dateComponents([.day], from: $0.0, to: $0.1).day == 1
}, "DST week advances by calendar days")
NSTimeZone.default = originalZone

// Failed loading must not silently overwrite the user's original stored data.
let invalidData = Data("invalid archive".utf8)
preferences.set(invalidData, forKey: "waterDiary.archive.v1")
let damaged = WaterStore(defaults: preferences)
check(damaged.errorMessage != nil && !damaged.add(amount: 250), "corrupt data blocks destructive overwrite")
check(preferences.data(forKey: "waterDiary.archive.v1") == invalidData, "corrupt source data retained")

print("\(checks) model checks passed.")
