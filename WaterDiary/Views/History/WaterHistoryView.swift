import SwiftUI

struct WaterHistoryView: View {
    @ObservedObject var store: WaterStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        List {
            if store.history.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "calendar.badge.clock").font(.largeTitle).foregroundStyle(WaterStyle.blue)
                    Text("还没有饮水记录").font(.headline)
                    Text("去首页记录第一杯水，日记就从今天开始。")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 44).listRowBackground(Color.clear)
            }
            ForEach(store.history) { day in
                NavigationLink {
                    WaterDayDetailView(store: store, date: day.date)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(verbatim: day.date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh_CN")))).font(.headline)
                            Spacer()
                            if day.isComplete {
                                Label("已达标", systemImage: "checkmark.circle.fill")
                                    .font(.caption).foregroundStyle(WaterStyle.blue)
                            }
                        }
                        ProgressView(value: day.progress).tint(WaterStyle.blue)
                        HStack {
                            Text("\(day.amount) / \(day.goal) 毫升")
                            Spacer()
                            Text("\(day.count) 次")
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .animation(reduceMotion ? nil : .default, value: day.progress)
                }
            }
        }
        .animation(reduceMotion ? nil : .default, value: store.archive.entries)
        .listStyle(.insetGrouped).navigationTitle("饮水历史").navigationBarTitleDisplayMode(.inline)
    }
}
