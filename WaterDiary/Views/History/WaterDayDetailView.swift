import SwiftUI

struct WaterDayDetailView: View {
    @ObservedObject var store: WaterStore
    let date: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingEntry: WaterEntry?

    var body: some View {
        List {
            Section {
                HStack {
                    Text("当天饮水")
                    Spacer()
                    Text("\(store.day(for: date).amount) 毫升").foregroundStyle(WaterStyle.blue)
                }
                HStack {
                    Text("当天目标")
                    Spacer()
                    Text("\(store.day(for: date).goal) 毫升").foregroundStyle(.secondary)
                }
            }
            Section("饮水记录") {
                if store.entries(on: date).isEmpty {
                    Text("当天的记录已全部删除").foregroundStyle(.secondary)
                }
                ForEach(store.entries(on: date)) { entry in
                    Button { editingEntry = entry } label: { WaterEntryRow(entry: entry) }.buttonStyle(.automatic)
                }
            }
        }
        .animation(reduceMotion ? nil : .default, value: store.entries(on: date))
        .listStyle(.insetGrouped).navigationTitle(date.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_CN"))))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingEntry) { WaterEntryEditor(store: store, entry: $0) }
    }
}
