import SwiftUI

struct WaterEntryEditor: View {
    @ObservedObject var store: WaterStore
    let entry: WaterEntry?
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String
    @State private var date: Date
    @State private var confirmDelete = false

    init(store: WaterStore, entry: WaterEntry?) {
        self.store = store
        self.entry = entry
        _amount = State(initialValue: String(entry?.amount ?? store.archive.cupAmount))
        _date = State(initialValue: entry?.date ?? Date())
    }

    private var validAmount: Int? {
        guard let value = Int(amount), WaterStore.amountRange.contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        TextField("饮水量", text: $amount)
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .keyboardType(.numberPad).accessibilityLabel("饮水量，毫升")
                        Text("毫升").foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    HStack {
                        ForEach([150, 250, 350, 500], id: \.self) { value in
                            Button("\(value)") { amount = String(value) }
                                .buttonStyle(.bordered).frame(maxWidth: .infinity)
                                .accessibilityLabel("\(value) 毫升")
                        }
                    }
                } header: {
                    Text("这次喝了多少")
                } footer: {
                    Text("可填写 1–2000 毫升，按实际喝下的水量记录。")
                }
                Section("记录时间") {
                    DatePicker("时间", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute]).environment(\.locale, Locale(identifier: "zh_CN"))
                }
                if entry != nil {
                    Section {
                        Button("删除这条记录", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(entry == nil ? "记录喝水" : "编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let value = validAmount else { return }
                        let saved: Bool
                        if let entry = entry {
                            saved = store.edit(entry, amount: value, date: date)
                        } else {
                            saved = store.add(amount: value, date: date)
                        }
                        if saved { dismiss() }
                    }
                    .disabled(validAmount == nil)
                }
            }
            .confirmationDialog("删除这条饮水记录？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除记录", role: .destructive) {
                    if let entry = entry, store.delete(entry) { dismiss() }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("当天的饮水总量和进度会同时更新。")
            }
        }
        .navigationViewStyle(.stack)
    }
}
