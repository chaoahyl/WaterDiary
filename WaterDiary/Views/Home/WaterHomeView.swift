import SwiftUI

struct WaterHomeView: View {
    @ObservedObject var store: WaterStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedAmount = 250
    @State private var showAdd = false
    @State private var editingEntry: WaterEntry?
    @State private var showGoal = false
    @State private var lastAdded: WaterEntry?

    private var today: WaterDay { store.today }
    private var cupOptions: [Int] { Array(Set([150, 250, 350, store.archive.cupAmount])).sorted() }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    WaterProgressCard(today: today) { showGoal = true }
                    quickAdd
                    WaterWeekChart(days: store.recentDays, date: store.now)
                    records
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(WaterStyle.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    if let entry = lastAdded {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(WaterStyle.blue)
                            Text("已记录 \(entry.amount) 毫升").font(.subheadline)
                            Spacer()
                            Button("撤销") {
                                if store.delete(entry) { lastAdded = nil }
                            }
                            .font(.subheadline.bold())
                            Button { lastAdded = nil } label: {
                                Image(systemName: "xmark").font(.caption.bold()).frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("关闭记录提示")
                        }
                        .padding(.leading, 16).padding(.trailing, 6).padding(.vertical, 7)
                        .background(WaterStyle.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 22).padding(.bottom, 8)
                    }
                }
                .animation(reduceMotion ? nil : .default, value: lastAdded)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { selectedAmount = store.archive.cupAmount }
        .onChange(of: store.archive.cupAmount) { selectedAmount = $0 }
        .onChange(of: store.today.date) { _ in lastAdded = nil }
        .onChange(of: store.archive.entries) { entries in
            if let lastAdded = lastAdded, !entries.contains(lastAdded) { self.lastAdded = nil }
        }
        .sheet(isPresented: $showAdd) { WaterEntryEditor(store: store, entry: nil) }
        .sheet(item: $editingEntry) { WaterEntryEditor(store: store, entry: $0) }
        .sheet(isPresented: $showGoal) { WaterSettingEditor(store: store, kind: .goal) }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text(verbatim: store.now.formatted(.dateTime.month(.wide).day().weekday(.wide).locale(Locale(identifier: "zh_CN"))))
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("让喝水，成为日常")
                    .font(.system(.title2, design: .rounded).bold())
            }
            Spacer(minLength: 10)
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 43)).foregroundStyle(WaterStyle.blue)
                .accessibilityHidden(true)
        }
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("喝一杯水").font(.headline)
                Spacer()
                Button("自定义") { showAdd = true }.font(.subheadline).padding(.vertical, 12)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 68))], spacing: 10) {
                ForEach(cupOptions, id: \.self) { amount in
                    Button { selectedAmount = amount } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "mug.fill").font(.title3)
                            Text("\(amount) 毫升").font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .foregroundStyle(selectedAmount == amount ? WaterStyle.blue : .secondary)
                        .background(selectedAmount == amount ? WaterStyle.blue.opacity(0.10) : WaterStyle.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(selectedAmount == amount ? WaterStyle.blue : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.automatic)
                    .accessibilityLabel("\(amount) 毫升")
                    .accessibilityAddTraits(selectedAmount == amount ? .isSelected : [])
                }
            }
            .animation(reduceMotion ? nil : .default, value: selectedAmount)
            Button {
                if store.add(amount: selectedAmount) { lastAdded = store.archive.entries.last }
            } label: {
                Label("记录喝水 · \(selectedAmount) 毫升", systemImage: "plus")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 18)
                    .foregroundStyle(.white).background(WaterStyle.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.automatic)
        }
    }

    private var records: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日记录").font(.headline)
                Spacer()
                Text("\(today.count) 次").font(.subheadline).foregroundStyle(.secondary)
            }
            if store.todayEntries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "drop").font(.title).foregroundStyle(WaterStyle.aqua)
                    Text("今天的第一杯，从现在开始").font(.subheadline).foregroundStyle(.secondary)
                    Text("选择杯量，点击「记录喝水」").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.todayEntries) { entry in
                        Button { editingEntry = entry } label: { WaterEntryRow(entry: entry) }
                            .buttonStyle(.automatic)
                        if entry.id != store.todayEntries.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .padding(.horizontal, 16).background(WaterStyle.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                Text("点击记录可修改或删除").font(.caption).foregroundStyle(.secondary)
            }
        }
        .animation(reduceMotion ? nil : .default, value: store.todayEntries)
    }
}
