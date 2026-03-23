//
//  HolidayViewModel.swift
//  下班助手
//
//  节假日视图模型，负责管理周末和节假日倒计时
//

import Foundation
import Combine

/// 节假日视图模型，负责管理周末和节假日倒计时
class HolidayViewModel: ObservableObject {
    @Published var timeUntilWeekend: String = ""
    @Published var daysUntilWeekend: Int = 0
    @Published var nextHoliday: Holiday?
    @Published var daysUntilNextHoliday: Int = 0
    @Published var timeUntilNextHoliday: String = ""
    @Published var holidays: [Holiday] = []  // 公开 holidays 数组

    private var cancellables = Set<AnyCancellable>()
    private let configManager: ConfigManager
    private let apiService = HolidayAPIService.shared

    init(configManager: ConfigManager) {
        self.configManager = configManager
        loadHolidays()
        startTimer()
    }

    private func loadHolidays() {
        let currentYear = Calendar.current.component(.year, from: Date())

        // 每次启动时从 API 获取数据
        apiService.fetchYearHolidays(year: currentYear) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let holidays):
                    self?.holidays = holidays
                    self?.updateNextHoliday()
                    print("成功获取 \(holidays.count) 个节假日数据")
                case .failure(let error):
                    print("获取节假日数据失败: \(error)")
                    self?.holidays = []
                    self?.nextHoliday = nil
                    self?.daysUntilNextHoliday = 0
                    self?.timeUntilNextHoliday = ""
                }
            }
        }
    }

    private func updateNextHoliday() {
        let today = Date()
        let calendar = Calendar.current
        let config = configManager.config

        // 找到下一个放假的节假日（假期前一天下班就算到假期）
        let upcomingHolidays = holidays
            .filter { $0.isOffDay }
            .compactMap { holiday -> (Holiday, Date)? in
                guard let date = holiday.dateObject else { return nil }
                return (holiday, date)
            }
            .sorted { $0.1 < $1.1 }

        // 找到第一个连续假期的开始日期
        var holidayGroups: [(name: String, startDate: Date, endDate: Date)] = []
        var currentGroup: (name: String, startDate: Date, endDate: Date)?

        for (holiday, date) in upcomingHolidays {
            if let group = currentGroup {
                // 检查是否是连续的假期
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: group.endDate),
                   calendar.isDate(date, inSameDayAs: nextDay) {
                    currentGroup = (group.name, group.startDate, date)
                } else {
                    holidayGroups.append(group)
                    currentGroup = (holiday.name, date, date)
                }
            } else {
                currentGroup = (holiday.name, date, date)
            }
        }
        if let group = currentGroup {
            holidayGroups.append(group)
        }

        // 找到下一个假期组
        for group in holidayGroups {
            // 计算假期前一天的下班时间
            guard let dayBeforeHoliday = calendar.date(byAdding: .day, value: -1, to: group.startDate) else {
                continue
            }

            var components = calendar.dateComponents([.year, .month, .day], from: dayBeforeHoliday)
            if let endTime = config.timeToDate(config.endTime) {
                let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                components.hour = endComponents.hour
                components.minute = endComponents.minute
                components.second = 0
            }

            if let holidayStartTime = calendar.date(from: components), holidayStartTime > today {
                nextHoliday = Holiday(name: group.name, date: dateString(from: group.startDate), isOffDay: true)

                let interval = holidayStartTime.timeIntervalSince(today)
                let days = Int(interval) / 86400
                let hours = (Int(interval) % 86400) / 3600
                let minutes = (Int(interval) % 3600) / 60
                let seconds = Int(interval) % 60

                daysUntilNextHoliday = days

                if days > 0 {
                    timeUntilNextHoliday = "\(days)天\(hours)小时\(minutes)分\(seconds)秒"
                } else if hours > 0 {
                    timeUntilNextHoliday = "\(hours)小时\(minutes)分\(seconds)秒"
                } else if minutes > 0 {
                    timeUntilNextHoliday = "\(minutes)分\(seconds)秒"
                } else {
                    timeUntilNextHoliday = "\(seconds)秒"
                }
                return
            }
        }

        // 如果没有找到未来的假期
        nextHoliday = nil
        daysUntilNextHoliday = 0
        timeUntilNextHoliday = ""
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func startTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateWeekendCountdown()
                self?.updateNextHoliday()
            }
            .store(in: &cancellables)
    }

    private func updateWeekendCountdown() {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let config = configManager.config

        // 如果已经是周末，显示周末中
        if weekday == 1 || weekday == 7 {
            timeUntilWeekend = "周末中"
            daysUntilWeekend = 0
            return
        }

        // 如果是周五，检查是否已经下班
        if weekday == 6 { // 周五
            if let endTime = config.timeToDate(config.endTime) {
                if now >= endTime {
                    // 周五已下班，算作周末
                    timeUntilWeekend = "周末中"
                    daysUntilWeekend = 0
                    return
                }
            }
        }

        // 计算到周五下班时间
        let daysUntilFriday = (6 - weekday + 7) % 7

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += daysUntilFriday

        // 设置为周五的下班时间
        if let endTime = config.timeToDate(config.endTime) {
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            components.hour = endComponents.hour
            components.minute = endComponents.minute
            components.second = 0
        }

        if let fridayEnd = calendar.date(from: components) {
            let interval = fridayEnd.timeIntervalSince(now)

            if interval <= 0 {
                timeUntilWeekend = "周末中"
                daysUntilWeekend = 0
                return
            }

            let days = Int(interval) / 86400
            let hours = (Int(interval) % 86400) / 3600
            let minutes = (Int(interval) % 3600) / 60
            let seconds = Int(interval) % 60

            daysUntilWeekend = days

            if days > 0 {
                timeUntilWeekend = "\(days)天\(hours)小时\(minutes)分\(seconds)秒"
            } else if hours > 0 {
                timeUntilWeekend = "\(hours)小时\(minutes)分\(seconds)秒"
            } else if minutes > 0 {
                timeUntilWeekend = "\(minutes)分\(seconds)秒"
            } else {
                timeUntilWeekend = "\(seconds)秒"
            }
        }
    }
}
