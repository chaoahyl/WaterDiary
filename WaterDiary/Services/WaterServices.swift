import Foundation
import Combine

/// Keeps drink reminders in step with the store.
/// The store itself stays unaware of them, so its data tests keep running on plain Foundation.
final class WaterServices: ObservableObject {
    let reminders = WaterReminders()

    private weak var store: WaterStore?
    private var cancellables = Set<AnyCancellable>()

    func attach(to store: WaterStore) {
        guard self.store == nil else { return }
        self.store = store

        // @Published emits before the property is set; hopping to the next main-queue turn
        // means the store's computed values (today) already include the change.
        store.$archive
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reschedule() }
            .store(in: &cancellables)

        // `now` is refreshed every 30 seconds; only a new calendar day matters here.
        store.$now
            .map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reschedule() }
            .store(in: &cancellables)

        reminders.refreshAuthorization(store: store)
    }

    /// Called when the app returns to the foreground.
    func appDidBecomeActive() {
        guard let store = store else { return }
        reminders.refreshAuthorization(store: store)
    }

    private func reschedule() {
        guard let store = store else { return }
        reminders.reschedule(for: store)
    }
}
