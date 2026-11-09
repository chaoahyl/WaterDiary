import SwiftUI

struct WaterWeekChart: View {
    let days: [WaterDay]
    let date: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("最近 7 天").font(.headline)
                Spacer()
                Text("达标 \(days.filter(\.isComplete).count) 天")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(days) { day in
                    VStack(spacing: 9) {
                        ZStack(alignment: .bottom) {
                            Capsule().fill(WaterStyle.blue.opacity(0.07))
                            Capsule().fill(day.isComplete ? WaterStyle.blue : WaterStyle.aqua)
                                .frame(height: 68 * day.progress)
                                .animation(reduceMotion ? nil : .default, value: day.progress)
                        }
                        .frame(width: 20, height: 68)
                        Text(Calendar.autoupdatingCurrent.isDate(day.date, inSameDayAs: date)
                             ? "今" : day.date.formatted(.dateTime.day().locale(Locale(identifier: "zh_CN"))))
                            .font(.caption2)
                            .foregroundStyle(Calendar.autoupdatingCurrent.isDate(day.date, inSameDayAs: date)
                                             ? WaterStyle.blue : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.date.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_CN"))))，\(day.amount) 毫升，目标 \(day.goal) 毫升")
                }
            }
        }
        .padding(20).background(WaterStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
