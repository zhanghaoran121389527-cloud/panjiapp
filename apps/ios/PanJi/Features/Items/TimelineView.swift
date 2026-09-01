import SwiftUI

/// 成长时间轴（线框 05）：左侧竖线 + 节点 + 日期标签 + 条目卡片；服务端已按 recordedDate 倒序、
/// 同日期 createdAt 倒序（契约 3.12），客户端保持原序渲染（验收①）。
struct TimelineView: View {
    let records: [RecordDTO]
    let emptyAction: () -> Void   // 「记录第一天」CTA

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceM) {
            Text("成长时间轴")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            if records.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                        TimelineRow(
                            record: record,
                            dateLabel: Self.dateLabel(for: record.recordedDate),
                            isFirst: index == 0,
                            isLast: index == records.count - 1)
                    }
                }
            }
        }
    }

    /// 空态（线框 05）：camera 圆底 + 标题 + 说明 + CTA（空态不显示时间轴线）
    private var emptyState: some View {
        VStack(spacing: CGFloat.PanJi.spaceM) {
            ZStack {
                Circle()
                    .fill(Color.PanJi.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "camera")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.PanJi.accent)
            }
            Text("还没有记录")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Text("拍下第一张照片，记下它的起点")
                .font(Font.PanJi.secondary)
                .foregroundStyle(Color.PanJi.textSecondary)
                .multilineTextAlignment(.center)
            Button("记录第一天", action: emptyAction)
                .buttonStyle(PanJiPrimaryButtonStyle())
                .frame(width: 240)
                .padding(.top, CGFloat.PanJi.spaceS)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CGFloat.PanJi.spaceXXXL)
    }

    /// 日期标签：北京今天 →「今天」；同年 →「M月d日」；跨年 →「yyyy年M月d日」（线框 05，裁决 A8）
    static func dateLabel(for dateString: String) -> String {
        let parts = dateString.split(separator: "-").map(String.init)
        guard parts.count == 3 else { return dateString }
        if dateString == Self.beijingToday() { return "今天" }
        let month = Int(parts[1]) ?? 0
        let day = Int(parts[2]) ?? 0
        if parts[0] == Self.beijingYear() {
            return "\(month)月\(day)日"
        }
        return "\(parts[0])年\(month)月\(day)日"
    }

    private static func beijingToday() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func beijingYear() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
}

/// 单行：左侧竖线（divider 2pt）+ 节点（accent 8pt）+ 日期标签 + 条目卡片
private struct TimelineRow: View {
    let record: RecordDTO
    let dateLabel: String
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: CGFloat.PanJi.spaceM) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.PanJi.divider)
                    .frame(width: 2, height: isFirst ? 0 : CGFloat.PanJi.spaceS)
                Circle()
                    .fill(Color.PanJi.accent)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.PanJi.divider)
                    .frame(width: 2)
                    .frame(maxHeight: isLast ? 0 : .infinity)
            }
            .frame(width: 8)
            .padding(.top, 4)   // 节点与日期标签文字中线对齐

            VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
                Text(dateLabel)
                    .font(Font.PanJi.caption)
                    .foregroundStyle(Color.PanJi.textSecondary)
                TimelineCellView(record: record)
            }
        }
    }
}
