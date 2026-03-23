//
//  WorkTimeConfig.swift
//  下班助手
//
//  工作时间配置模型，包含上班时间、下班时间、午休时间等信息
//

import Foundation

/// 工作时间配置模型，包含上班时间、下班时间、午休时间等信息
struct WorkTimeConfig: Codable {
    /// 上班时间（格式：HH:mm，如 "09:00"）
    var startTime: String
    /// 下班时间（格式：HH:mm，如 "18:00"）
    var endTime: String
    /// 午休开始时间（格式：HH:mm，如 "12:00"）
    var lunchStart: String
    /// 午休时长（分钟）
    var lunchDuration: Int

    /// 默认配置
    static let `default` = WorkTimeConfig(
        startTime: "09:00",
        endTime: "18:00",
        lunchStart: "12:00",
        lunchDuration: 60
    )

    /// 将时间字符串（如 "09:00"）转换为今天的 Date 对象
    /// - Parameter timeString: 时间字符串（格式：HH:mm）
    /// - Returns: Date 对象或 nil
    func timeToDate(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var finalComponents = components
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute

        return calendar.date(from: finalComponents)
    }

    /// 计算总工作时长（秒）
    var totalWorkSeconds: TimeInterval {
        guard let start = timeToDate(startTime),
              let end = timeToDate(endTime) else { return 0 }
        return end.timeIntervalSince(start) - Double(lunchDuration * 60)
    }
}
