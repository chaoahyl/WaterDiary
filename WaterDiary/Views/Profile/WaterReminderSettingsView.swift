import SwiftUI
import UIKit

struct WaterReminderSettingsView: View {
    @ObservedObject var store: WaterStore
    @ObservedObject var reminders: WaterReminders
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Toggle("喝水提醒", isOn: Binding(
                    get: { reminders.settings.isEnabled },
                    set: { reminders.setEnabled($0, store: store) }
                ))
            } footer: {
                if reminders.isDenied {
                    Button("通知权限已关闭，前往“设置”打开") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .font(.footnote)
                } else {
                    Text("今天达到目标后，当天剩下的提醒会自动取消。")
                }
            }

            if reminders.settings.isEnabled {
                Section {
                    Picker("开始", selection: hourBinding(\.startHour)) {
                        ForEach(Array(WaterReminderSettings.hourRange), id: \.self) { Text("\($0):00").tag($0) }
                    }
                    Picker("结束", selection: hourBinding(\.endHour)) {
                        ForEach(Array(reminders.settings.startHour...WaterReminderSettings.hourRange.upperBound), id: \.self) {
                            Text("\($0):00").tag($0)
                        }
                    }
                    Picker("间隔", selection: hourBinding(\.interval)) {
                        ForEach(WaterReminderSettings.intervals, id: \.self) { Text("\($0) 小时").tag($0) }
                    }
                } header: {
                    Text("提醒时间")
                } footer: {
                    Text("将在 " + reminders.settings.hours.map { "\($0):00" }.joined(separator: "、") + " 提醒。")
                }
            }
        }
        .navigationTitle("喝水提醒")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func hourBinding(_ keyPath: WritableKeyPath<WaterReminderSettings, Int>) -> Binding<Int> {
        Binding(
            get: { reminders.settings[keyPath: keyPath] },
            set: { value in
                var next = reminders.settings
                next[keyPath: keyPath] = value
                reminders.setHours(start: next.startHour, end: next.endHour, interval: next.interval, store: store)
            }
        )
    }
}
