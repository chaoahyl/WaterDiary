import SwiftUI

struct WaterProfileView: View {
    @ObservedObject var store: WaterStore
    @State private var setting: WaterSetting?

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "drop.fill").font(.system(size: 32)).foregroundStyle(WaterStyle.blue)
                            .frame(width: 66, height: 66)
                            .background(WaterStyle.blue.opacity(0.08)).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 7) {
                            Text("我的饮水日记").font(.title3.bold())
                            Text("照顾自己，从一杯水开始").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 12)
                    HStack(spacing: 0) {
                        statistic("\(store.recordedDays)", title: "记录天数")
                        statistic("\(store.streak)", title: "连续达标")
                        statistic(String(format: "%.1f", Double(store.totalAmount) / 1000), title: "累计 / 升")
                    }
                    .padding(.vertical, 12)
                }
                Section("饮水偏好") {
                    Button { setting = .goal } label: {
                        settingsRow("每日目标", icon: "scope", value: "\(store.archive.dailyGoal) 毫升")
                    }
                    Button { setting = .cup } label: {
                        settingsRow("常用杯量", icon: "mug", value: "\(store.archive.cupAmount) 毫升")
                    }
                }
                Section("我的记录") {
                    NavigationLink {
                        WaterHistoryView(store: store)
                    } label: {
                        Label("饮水历史", systemImage: "calendar")
                    }
                }
                Section {
                    Label("记录保存在这台设备上", systemImage: "iphone").font(.subheadline)
                    Text("每天从零开始，过去的记录会保留。按自己的需要设置目标，慢慢养成习惯。")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: {
                    Text("关于饮水日记")
                } footer: {
                    Text("饮水日记 · 每一杯，都是对自己的照顾")
                        .frame(maxWidth: .infinity).padding(.top, 16)
                }
            }
            .listStyle(.insetGrouped).navigationTitle("我的")
        }
        .navigationViewStyle(.stack)
        .sheet(item: $setting) { WaterSettingEditor(store: store, kind: $0) }
    }

    private func statistic(_ value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.system(.title2, design: .rounded).bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).accessibilityElement(children: .combine)
    }

    private func settingsRow(_ title: String, icon: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5).contentShape(Rectangle())
    }
}
