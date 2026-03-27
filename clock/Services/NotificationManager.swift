//
//  NotificationManager.swift
//  下班助手
//
//  通知管理器，负责管理下班和午休提醒通知
//

import Foundation
import Combine
import UserNotifications

/// 通知管理器，负责管理下班和午休提醒通知
class NotificationManager: ObservableObject {
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                requestPermission()
            }
        }
    }

    @Published var reminderMinutes: Int {
        didSet {
            UserDefaults.standard.set(reminderMinutes, forKey: "reminderMinutes")
        }
    }

    @Published var lunchReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(lunchReminderEnabled, forKey: "lunchReminderEnabled")
        }
    }

    @Published var lunchReminderMinutes: Int {
        didSet {
            UserDefaults.standard.set(lunchReminderMinutes, forKey: "lunchReminderMinutes")
        }
    }

    @Published var takeoutReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(takeoutReminderEnabled, forKey: "takeoutReminderEnabled")
        }
    }

    @Published var takeoutTime: String {
        didSet {
            UserDefaults.standard.set(takeoutTime, forKey: "takeoutTime")
        }
    }

    private var hasShownTodayReminder = false
    private var hasShownTodayLunchReminder = false
    private var hasShownTodayTakeoutReminder = false
    private var lastCheckedDate: Date?  // 记录上次检查的日期

    init() {
        // 检查是否是首次启动
        let hasLaunchedBefore = UserDefaults.standard.object(forKey: "notificationsEnabled") != nil

        if hasLaunchedBefore {
            self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        } else {
            // 首次启动，默认启用通知
            self.notificationsEnabled = true
            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        }

        let savedReminderMinutes = UserDefaults.standard.integer(forKey: "reminderMinutes")
        self.reminderMinutes = savedReminderMinutes == 0 ? 30 : savedReminderMinutes

        self.lunchReminderEnabled = UserDefaults.standard.bool(forKey: "lunchReminderEnabled")

        let savedLunchReminderMinutes = UserDefaults.standard.integer(forKey: "lunchReminderMinutes")
        self.lunchReminderMinutes = savedLunchReminderMinutes == 0 ? 10 : savedLunchReminderMinutes

        self.takeoutReminderEnabled = UserDefaults.standard.bool(forKey: "takeoutReminderEnabled")

        let savedTakeoutTime = UserDefaults.standard.string(forKey: "takeoutTime")
        self.takeoutTime = savedTakeoutTime ?? "11:30"

        // 请求通知权限
        if self.notificationsEnabled {
            requestPermission()
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func checkAndSendReminder(remainingSeconds: TimeInterval, status: WorkDayStatus) {
        guard notificationsEnabled else { return }

        let calendar = Calendar.current
        let today = Date()

        // 检查是否是新的一天，重置所有标志
        if let lastDate = lastCheckedDate, !calendar.isDate(lastDate, inSameDayAs: today) {
            hasShownTodayReminder = false
            hasShownTodayLunchReminder = false
            hasShownTodayTakeoutReminder = false
        }
        lastCheckedDate = today

        // 下班提醒
        if status == .working {
            let remainingMinutes = Int(remainingSeconds / 60)

            // 当剩余时间在设定的提醒时间附近时发送通知（有2分钟的窗口）
            if remainingMinutes <= reminderMinutes && remainingMinutes >= reminderMinutes - 1 && !hasShownTodayReminder {
                sendNotification(remainingMinutes: remainingMinutes)
                hasShownTodayReminder = true
            }
        } else if status == .beforeWork {
            // 如果还没上班，重置提醒标志
            hasShownTodayReminder = false
        }
    }

    func checkAndSendLunchReminder(timeUntilLunch: TimeInterval) {
        guard lunchReminderEnabled else { return }

        let remainingMinutes = Int(timeUntilLunch / 60)

        // 当距离午休时间在设定的提醒时间附近时发送通知（有2分钟的窗口）
        if remainingMinutes <= lunchReminderMinutes && remainingMinutes >= lunchReminderMinutes - 1 && timeUntilLunch > 0 && !hasShownTodayLunchReminder {
            sendLunchNotification(remainingMinutes: remainingMinutes)
            hasShownTodayLunchReminder = true
        }

        // 如果已经过了午休时间，重置标志
        if timeUntilLunch < -60 {  // 超过午休时间1分钟后才重置，避免边界问题
            hasShownTodayLunchReminder = false
        }
    }

    func checkAndSendTakeoutReminder() {
        guard takeoutReminderEnabled else { return }

        let calendar = Calendar.current
        let now = Date()

        // 检查是否是新的一天，重置外卖提醒标志
        if let lastDate = lastCheckedDate, !calendar.isDate(lastDate, inSameDayAs: now) {
            hasShownTodayTakeoutReminder = false
        }

        // 解析外卖时间
        let timeComponents = takeoutTime.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]),
              hour >= 0 && hour < 24,
              minute >= 0 && minute < 60 else {
            return
        }

        // 创建今天的外卖时间
        var takeoutComponents = calendar.dateComponents([.year, .month, .day], from: now)
        takeoutComponents.hour = hour
        takeoutComponents.minute = minute
        takeoutComponents.second = 0

        guard let takeoutDate = calendar.date(from: takeoutComponents) else {
            return
        }

        // 检查是否到了外卖提醒时间
        let timeDifference = takeoutDate.timeIntervalSince(now)

        // 当时间差在 -30 到 60 秒之间时发送通知（允许更大的窗口）
        // -30 秒表示已经过了30秒内也可以触发
        if timeDifference >= -30 && timeDifference <= 60 && !hasShownTodayTakeoutReminder {
            sendTakeoutNotification()
            hasShownTodayTakeoutReminder = true
        }
    }

    private func sendTakeoutNotification() {
        // 优先使用宠物提醒
        if PetManager.shared.config.enabled {
            PetManager.shared.showPet(withMessage: "该点外卖了！记得按时吃饭哦～")
            return
        }

        // 如果宠物未启用，使用系统通知
        let content = UNMutableNotificationContent()
        content.title = "外卖提醒"
        content.body = "该点外卖了！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "takeoutReminder",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send takeout notification: \(error)")
            }
        }
    }

    private func sendNotification(remainingMinutes: Int) {
        // 优先使用宠物提醒
        if PetManager.shared.config.enabled {
            PetManager.shared.showPet(withMessage: "还有 \(remainingMinutes) 分钟就下班了！记得保存工作哦～")
            return
        }

        // 如果宠物未启用，使用系统通知
        let content = UNMutableNotificationContent()
        content.title = "下班提醒"
        content.body = "还有 \(remainingMinutes) 分钟就下班了！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "workEndReminder",
            content: content,
            trigger: nil // 立即发送
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    private func sendLunchNotification(remainingMinutes: Int) {
        // 优先使用宠物提醒
        if PetManager.shared.config.enabled {
            PetManager.shared.showPet(withMessage: "还有 \(remainingMinutes) 分钟就到午休时间了！该准备吃饭啦～")
            return
        }

        // 如果宠物未启用，使用系统通知
        let content = UNMutableNotificationContent()
        content.title = "午休提醒"
        content.body = "还有 \(remainingMinutes) 分钟就到午休时间了！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "lunchReminder",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send lunch notification: \(error)")
            }
        }
    }

    // 发送下班通知
    func sendWorkEndNotification() {
        guard notificationsEnabled else { return }

        // 优先使用宠物提醒
        if PetManager.shared.config.enabled {
            PetManager.shared.showPet(withMessage: "下班啦！辛苦了一天，该好好休息了 🎉")
            return
        }

        // 如果宠物未启用，使用系统通知
        let content = UNMutableNotificationContent()
        content.title = "下班啦！"
        content.body = "辛苦了一天，该休息了 🎉"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "workEnd",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
