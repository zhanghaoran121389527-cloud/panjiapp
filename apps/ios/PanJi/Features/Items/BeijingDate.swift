import Foundation

/// 北京时间工具（裁决 A8/A13）：日期选择上限、今天、YYYY-MM-DD 解析/格式化统一在此维护。
/// 供 Items（创建/编辑）与 Records（补录）共用，避免各 store 重复持有。
enum BeijingDate {
    static let timeZone = TimeZone(identifier: "Asia/Shanghai")!

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// 北京时间今天 23:59:59（日期选择上限）
    static func endOfToday() -> Date {
        calendar.startOfDay(for: Date()).addingTimeInterval(86_399)
    }

    /// 北京时间今天 00:00:00（记录日期默认值）
    static func todayDate() -> Date {
        calendar.startOfDay(for: Date())
    }

    /// Date → "YYYY-MM-DD"（按北京时间取日历日）
    static func string(from date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    /// "YYYY-MM-DD" → Date（北京时间当日 00:00:00；解析失败返回 nil）
    static func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
