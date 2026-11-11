import Foundation
import UserNotifications

/// When to remind: every `interval` hours from `startHour` to `endHour` (inclusive).
struct WaterReminderSettings: Codable, Equatable {
    static let hourRange = 6...23
    static let intervals = [1, 2, 3]

    var isEnabled = false
    var startHour = 9
    var endHour = 21
    var interval = 2

    var hours: [Int] {
        guard startHour <= endHour, interval > 0 else { return [] }
        return Array(stride(from: startHour, through: endHour, by: interval))
    }

    var summary: String {
        isEnabled ? "每 \(interval) 小时 · \(startHour):00–\(endHour):00" : "已关闭"
    }
}

/// Local drink reminders. Notifications are scheduled one by one for the coming days (not as a
/// repeating trigger) so that today's remaining reminders can be dropped once the goal is met.
final class WaterReminders: ObservableObject {
    private static let storageKey = "waterDiary.reminders.v1"
    private static let identifierPrefix = "waterDiary.reminder."
    /// iOS keeps at most 64 pending local notifications per app; stay below that.
    private static let pendingLimit = 60
    private static let maxDays = 7

    @Published private(set) var settings: WaterReminderSettings
    @Published private(set) var isDenied = false

    private let defaults: UserDefaults
    private let center = UNUserNotificationCenter.current()
    private var calendar: Calendar { .autoupdatingCurrent }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(WaterReminderSettings.self, from: data) {
            settings = saved
        } else {
            settings = WaterReminderSettings()
        }
    }

    /// Turning reminders on asks for notification permission first; `completion` gets the result.
    func setEnabled(_ enabled: Bool, store: WaterStore, completion: ((Bool) -> Void)? = nil) {
        guard enabled else {
            update { $0.isEnabled = false }
            reschedule(for: store)
            completion?(true)
            return
        }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isDenied = !granted
                if granted {
                    self.update { $0.isEnabled = true }
                    self.reschedule(for: store)
                }
                completion?(granted)
            }
        }
    }

    func setHours(start: Int, end: Int, interval: Int, store: WaterStore) {
        update {
            $0.startHour = start
            $0.endHour = max(start, end)
            $0.interval = interval
        }
        reschedule(for: store)
    }

    /// Re-reads the permission, which the user can change in Settings at any time.
    func refreshAuthorization(store: WaterStore) {
        center.getNotificationSettings { notificationSettings in
            DispatchQueue.main.async {
                self.isDenied = notificationSettings.authorizationStatus == .denied
                self.reschedule(for: store)
            }
        }
    }

    /// Replaces every pending reminder of this app with a fresh plan based on today's progress.
    func reschedule(for store: WaterStore, now: Date = Date()) {
        // A placeholder archive (failed load) would claim nothing was drunk today.
        guard store.canSave else { return }
        let requests = settings.isEnabled && !isDenied ? plan(for: store, now: now) : []
        // Reminders are this app's only notifications, so clearing all pending ones is safe.
        // Removing and adding from the same thread keeps the calls in order.
        center.removeAllPendingNotificationRequests()
        requests.forEach { center.add($0) }
    }

    private func plan(for store: WaterStore, now: Date) -> [UNNotificationRequest] {
        let hours = settings.hours
        guard !hours.isEmpty else { return [] }
        let today = store.today
        let days = min(Self.maxDays, Self.pendingLimit / hours.count)
        let startOfToday = calendar.startOfDay(for: now)

        return (0..<days).flatMap { offset -> [UNNotificationRequest] in
            // Goal met today: nothing more to remind about until tomorrow.
            if offset == 0 && today.isComplete { return [] }
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { return [] }
            return hours.compactMap { hour in
                guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                      fire > now else { return nil }
                let content = UNMutableNotificationContent()
                content.title = "该喝水啦"
                content.body = offset == 0
                    ? "今天已喝 \(today.amount) 毫升，离目标还差 \(max(today.goal - today.amount, 0)) 毫升。"
                    : "喝一杯水吧，今天的目标是 \(store.archive.dailyGoal) 毫升。"
                content.sound = .default
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                return UNNotificationRequest(identifier: Self.identifierPrefix + "\(Int(fire.timeIntervalSince1970))",
                                             content: content, trigger: trigger)
            }
        }
    }

    private func update(_ change: (inout WaterReminderSettings) -> Void) {
        var updated = settings
        change(&updated)
        settings = updated
        if let data = try? JSONEncoder().encode(updated) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
