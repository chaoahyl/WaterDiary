import SwiftUI

struct WaterEntryRow: View {
    let entry: WaterEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "drop.fill").font(.body).foregroundStyle(WaterStyle.blue)
                .frame(width: 42, height: 42).background(WaterStyle.blue.opacity(0.08)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("喝水").font(.subheadline.weight(.medium))
                Text(verbatim: entry.date.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_CN")))).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("+\(entry.amount) 毫升").font(.system(.body, design: .rounded).weight(.semibold))
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary).padding(.vertical, 13).contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.date.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_CN"))))，喝水 \(entry.amount) 毫升，编辑记录")
    }
}
