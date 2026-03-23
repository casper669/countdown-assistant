//
//  CountdownViewModel.swift
//  下班助手
//
//  倒计时视图模型，负责管理倒计时的业务逻辑
//

import Foundation
import Combine

/// 倒计时视图模型，负责管理倒计时的业务逻辑
class CountdownViewModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var status: WorkDayStatus = .working
    @Published var displayText: String = "00:00:00"

    private var timer: Timer?
    private let configManager: ConfigManager
    private let notificationManager: NotificationManager
    private let holidayViewModel: HolidayViewModel?  // 添加 holidayViewModel 引用
    private var previousStatus: WorkDayStatus = .working

    init(configManager: ConfigManager, notificationManager: NotificationManager, holidayViewModel: HolidayViewModel? = nil) {
        self.configManager = configManager
        self.notificationManager = notificationManager
        self.holidayViewModel = holidayViewModel
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
        // 确保 Timer 在所有 RunLoop 模式下都能运行
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        updateCountdown()
    }

    private func updateCountdown() {
        let config = configManager.config
        let holidays = holidayViewModel?.holidays ?? []
        status = CountdownCalculator.calculateStatus(config: config, holidays: holidays)
        remainingTime = CountdownCalculator.calculateRemainingTime(config: config)

        // 检查是否需要发送通知
        notificationManager.checkAndSendReminder(remainingSeconds: remainingTime, status: status)

        // 检查午休提醒
        if status == .working {
            let timeUntilLunch = calculateTimeUntilLunch(config: config)
            if timeUntilLunch > 0 {
                notificationManager.checkAndSendLunchReminder(timeUntilLunch: timeUntilLunch)
            }
        }

        // 检查是否刚下班
        if previousStatus == .working && status == .afterWork {
            notificationManager.sendWorkEndNotification()
        }
        previousStatus = status

        switch status {
        case .working, .lunch:
            displayText = CountdownCalculator.formatTimeInterval(remainingTime)
        case .beforeWork:
            displayText = "未上班"
        case .afterWork:
            displayText = "已下班"
        case .weekend:
            displayText = "周末"
        case .holiday:
            displayText = "节假日"
        }

        // 通知状态栏更新
        NotificationCenter.default.post(name: NSNotification.Name("UpdateStatusBar"), object: nil)
    }

    private func calculateTimeUntilLunch(config: WorkTimeConfig) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()

        guard let lunchStart = config.timeToDate(config.lunchStart) else {
            return 0
        }

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let lunchComponents = calendar.dateComponents([.hour, .minute], from: lunchStart)
        components.hour = lunchComponents.hour
        components.minute = lunchComponents.minute
        components.second = 0

        guard let lunchTime = calendar.date(from: components) else {
            return 0
        }

        return lunchTime.timeIntervalSince(now)
    }

    deinit {
        timer?.invalidate()
    }
}
