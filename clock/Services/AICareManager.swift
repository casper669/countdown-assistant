//
//  AICareManager.swift
//  下班助手
//
//  AI 关怀管理器，负责管理 AI 关怀功能的逻辑
//

import Foundation
import Combine
import UserNotifications

/// AI 关怀管理器，负责管理 AI 关怀功能的逻辑
class AICareManager: ObservableObject {
    @Published var config: AIConfig {
        didSet {
            save()
        }
    }

    @Published var isTesting: Bool = false
    @Published var testResult: String?

    private let userDefaultsKey = "aiConfig"
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// 初始化方法
    init() {
        do {
            if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
                let decoded = try JSONDecoder().decode(AIConfig.self, from: data)
                self.config = decoded
            } else {
                self.config = .default
            }
        } catch {
            print("加载 AI 配置失败: \(error)")
            self.config = .default
        }
        startTimer()
    }

    /// 启动定时器，每 60 秒检查一次是否需要发送关怀提醒
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkAndSendCare()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// 检查是否需要发送关怀提醒，并在需要时发送
    func checkAndSendCare() {
        guard config.enabled else { return }
        guard !config.apiKey.isEmpty else { return }
        guard config.shouldSendReminder() else { return }

        let now = Date()
        guard isWorkTime(currentTime: now) else { return }

        var updatedConfig = config
        updatedConfig.lastReminderDate = now
        config = updatedConfig

        AIAPIService.shared.getCareMessage(config: config) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.sendNotification(message: message)
                case .failure(let error):
                    print("AI API 调用失败: \(error.localizedDescription)")
                    let defaultMessage = AIAPIService.shared.getDefaultCareMessage()
                    self?.sendNotification(message: defaultMessage)
                }
            }
        }
    }

    /// 测试 AI 配置是否有效
    func testConfiguration() {
        isTesting = true
        testResult = nil

        AIAPIService.shared.sendTestRequest(config: config) { [weak self] result in
            DispatchQueue.main.async {
                self?.isTesting = false

                switch result {
                case .success(let message):
                    self?.testResult = "✅ 连接成功！\n\nAI 回复：\(message)"
                case .failure(let error):
                    self?.testResult = "❌ 连接失败！\n\n错误信息：\(error.localizedDescription)"
                }
            }
        }
    }

    /// 检查当前时间是否在工作时间内
    /// - Parameter currentTime: 当前时间
    /// - Returns: 是否在工作时间内
    private func isWorkTime(currentTime: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentTime)
        let hour = calendar.component(.hour, from: currentTime)

        if weekday == 1 || weekday == 7 {
            return false
        }

        return hour >= 9 && hour < 18
    }

    /// 发送关怀通知
    /// - Parameter message: 通知内容
    private func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "💡 温馨关怀"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送关怀通知失败: \(error.localizedDescription)")
            }
        }
    }

    /// 保存配置到 UserDefaults
    private func save() {
        do {
            let encoded = try JSONEncoder().encode(config)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("保存 AI 配置失败: \(error)")
        }
    }

    /// 验证并确保提醒间隔的有效性
    func validateReminderIntervalIfNeeded() {
        if config.reminderIntervalMinutes < 1 {
            var updatedConfig = config
            updatedConfig.reminderIntervalMinutes = 1
            config = updatedConfig
        }
    }

    /// 立即触发关怀提醒
    func triggerCareNow() {
        var updatedConfig = config
        updatedConfig.lastReminderDate = Date()
        config = updatedConfig

        AIAPIService.shared.getCareMessage(config: config) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.sendNotification(message: message)
                case .failure(let error):
                    print("AI API 调用失败: \(error.localizedDescription)")
                    let defaultMessage = AIAPIService.shared.getDefaultCareMessage()
                    self?.sendNotification(message: defaultMessage)
                }
            }
        }
    }

    /// 重置最后一次提醒的日期
    func resetLastReminder() {
        var updatedConfig = config
        updatedConfig.lastReminderDate = nil
        config = updatedConfig
    }

    deinit {
        timer?.invalidate()
    }
}
