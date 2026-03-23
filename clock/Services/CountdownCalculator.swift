//
//  CountdownCalculator.swift
//  下班助手
//
//  倒计时计算器，负责计算工作状态和剩余时间
//

import Foundation

/// 倒计时计算器，负责计算工作状态和剩余时间
class CountdownCalculator {

    /// 计算当前的工作日状态
    /// - Parameters:
    ///   - config: 工作时间配置
    ///   - holidays: 节假日列表
    ///   - currentTime: 当前时间
    /// - Returns: 工作日状态
    static func calculateStatus(config: WorkTimeConfig, holidays: [Holiday] = [], currentTime: Date = Date()) -> WorkDayStatus {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentTime)

        // 节假日判断
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentTime)

        if let holiday = holidays.first(where: { $0.date == dateString && $0.isOffDay }) {
            return .holiday
        }

        // 周末判断（周六=7，周日=1）
        if weekday == 1 || weekday == 7 {
            return .weekend
        }

        guard let startTime = config.timeToDate(config.startTime),
              let endTime = config.timeToDate(config.endTime),
              let lunchStart = config.timeToDate(config.lunchStart) else {
            return .afterWork
        }

        let lunchEnd = lunchStart.addingTimeInterval(Double(config.lunchDuration * 60))

        // 判断当前状态
        if currentTime < startTime {
            return .beforeWork
        } else if currentTime >= startTime && currentTime < lunchStart {
            return .working
        } else if currentTime >= lunchStart && currentTime < lunchEnd {
            return .lunch
        } else if currentTime >= lunchEnd && currentTime < endTime {
            return .working
        } else {
            return .afterWork
        }
    }

    /// 计算距离下班的剩余时间
    /// - Parameters:
    ///   - config: 工作时间配置
    ///   - currentTime: 当前时间
    /// - Returns: 剩余时间（秒）
    static func calculateRemainingTime(config: WorkTimeConfig, currentTime: Date = Date()) -> TimeInterval {
        let status = calculateStatus(config: config, currentTime: currentTime)

        guard status == .working || status == .lunch else {
            return 0
        }

        guard let endTime = config.timeToDate(config.endTime),
              let lunchStart = config.timeToDate(config.lunchStart) else {
            return 0
        }

        let lunchEnd = lunchStart.addingTimeInterval(Double(config.lunchDuration * 60))

        // 如果在午休中，剩余时间 = 午休结束到下班的时间
        if status == .lunch {
            return endTime.timeIntervalSince(lunchEnd)
        }

        // 如果在工作中
        if currentTime < lunchStart {
            // 上午工作中：剩余时间 = 午饭前剩余 + 午饭后到下班
            let beforeLunch = lunchStart.timeIntervalSince(currentTime)
            let afterLunch = endTime.timeIntervalSince(lunchEnd)
            return beforeLunch + afterLunch
        } else {
            // 下午工作中：剩余时间 = 当前到下班
            return endTime.timeIntervalSince(currentTime)
        }
    }

    /// 格式化时间间隔为 HH:mm:ss 格式
    /// - Parameter interval: 时间间隔（秒）
    /// - Returns: 格式化后的字符串
    static func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
