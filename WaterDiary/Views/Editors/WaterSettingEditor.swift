import SwiftUI

enum WaterSetting: String, Identifiable {
    case goal, cup
    var id: String { rawValue }
    var title: String { self == .goal ? "每日目标" : "常用杯量" }
    var options: [Int] { self == .goal ? [1500, 2000, 2500, 3000] : [150, 250, 350, 500] }
    var range: ClosedRange<Int> { self == .goal ? WaterStore.goalRange : WaterStore.amountRange }
}

struct WaterSettingEditor: View {
    @ObservedObject var store: WaterStore
    let kind: WaterSetting
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var amount: String

    init(store: WaterStore, kind: WaterSetting) {
        self.store = store
        self.kind = kind
        _amount = State(initialValue: String(kind == .goal ? store.archive.dailyGoal : store.archive.cupAmount))
    }

    private var validAmount: Int? {
        guard let value = Int(amount), kind.range.contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        TextField(kind.title, text: $amount).keyboardType(.numberPad)
                            .font(.system(.title, design: .rounded).bold())
                            .accessibilityLabel("\(kind.title)，毫升")
                        Text("毫升").foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    ForEach(kind.options, id: \.self) { value in
                        Button { amount = String(value) } label: {
                            HStack {
                                Text("\(value) 毫升").foregroundStyle(.primary)
                                Spacer()
                                if Int(amount) == value { Image(systemName: "checkmark").foregroundStyle(WaterStyle.blue) }
                            }
                            .padding(.vertical, 7).contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(Int(amount) == value ? .isSelected : [])
                    }
                    .animation(reduceMotion ? nil : .default, value: amount)
                } header: {
                    Text(kind == .goal ? "找到适合自己的节奏" : "选择最常用的杯子容量")
                } footer: {
                    Text(kind == .goal
                         ? "可设置 500–10000 毫升。新目标对今天和以后生效，历史记录保持原来的目标。"
                         : "可设置 1–2000 毫升。首页会默认选中这个杯量。")
                }
            }
            .navigationTitle(kind.title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let value = validAmount else { return }
                        let saved = kind == .goal ? store.setGoal(value) : store.setCupAmount(value)
                        if saved { dismiss() }
                    }
                    .disabled(validAmount == nil)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
