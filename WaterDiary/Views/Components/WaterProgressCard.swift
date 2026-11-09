import SwiftUI

struct WaterProgressCard: View {
    let today: WaterDay
    let onEditGoal: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("今日饮水").font(.headline)
                Spacer()
                Button(action: onEditGoal) {
                    HStack(spacing: 4) {
                        Text("目标 \(today.goal) 毫升")
                        Image(systemName: "chevron.right").font(.caption2.bold())
                    }
                    .font(.subheadline).padding(.vertical, 10)
                }
                .accessibilityLabel("修改每日目标，当前 \(today.goal) 毫升")
            }
            WaterGauge(progress: today.progress, amount: today.amount, complete: today.isComplete)
                .frame(height: 245)
                .animation(reduceMotion ? nil : .default, value: today.progress)
            Text(today.isComplete ? "今日目标已达成，保持自己的节奏" : "小口慢饮，每一杯都算数")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 0) {
                metric(value: "\(Int(today.progress * 100))%", title: "今日进度")
                Divider().frame(height: 32)
                metric(value: "\(max(today.goal - today.amount, 0))", title: "还差 / 毫升")
                Divider().frame(height: 32)
                metric(value: "\(today.count)", title: "饮水次数")
            }
            .padding(.top, 6)
        }
        .padding(20).background(WaterStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func metric(value: String, title: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.system(.title3, design: .rounded).bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct WaterGauge: View {
    let progress: Double
    let amount: Int
    let complete: Bool

    var body: some View {
        ZStack {
            Circle().stroke(WaterStyle.blue.opacity(0.08), lineWidth: 12)
            Circle().trim(from: 0, to: progress)
                .stroke(WaterStyle.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 6) {
                Image(systemName: complete ? "checkmark.seal.fill" : "drop.fill")
                    .font(.system(size: 40)).foregroundStyle(WaterStyle.blue)
                Text("\(amount)")
                    .font(.system(size: 47, weight: .bold, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                Text(complete ? "今日已达标 / 毫升" : "已喝 / 毫升")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(28)
        }
        .padding(10).frame(maxWidth: 245)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今日已喝 \(amount) 毫升，完成 \(Int(progress * 100))%")
    }
}
