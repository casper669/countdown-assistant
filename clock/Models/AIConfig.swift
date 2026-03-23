//
//  AIConfig.swift
//  下班助手
//
//  AI 关怀助手的配置和服务格式定义
//

import Foundation

/// AI 服务格式枚举，支持 OpenAI 格式和 Anthropic 格式
enum AIServiceFormat: String, Codable, CaseIterable, Identifiable {
    case openAI    // 兼容 OpenAI 格式（包括智谱的 OpenAI 兼容 API）
    case anthropic  // Anthropic 格式

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI 格式"
        case .anthropic: return "Anthropic 格式"
        }
    }

    /// API Key 占位符
    var apiKeyPlaceholder: String {
        switch self {
        case .openAI: return "sk-xxxxxx"
        case .anthropic: return "sk-ant-api03-xxxxxx"
        }
    }

    /// 默认基础 URL
    var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://open.bigmodel.cn/api/paas/v4/chat/completions"  // 智普 AI 的 OpenAI 兼容 API
        case .anthropic: return "https://api.anthropic.com/v1/messages"
        }
    }

    /// 默认模型
    var defaultModel: String {
        switch self {
        case .openAI: return "GLM-4.7-Flash"  // 智普的免费模型
        case .anthropic: return "claude-3-5-sonnet-20240620"
        }
    }

    /// 测试用的提示词
    var testPrompt: String {
        switch self {
        case .openAI: return "测试连接 - 你好！"
        case .anthropic: return "测试连接 - 你好！"
        }
    }
}

/// AI 关怀助手配置结构体
struct AIConfig: Codable {
    /// 是否启用 AI 关怀功能
    var enabled: Bool
    /// 服务格式
    var serviceFormat: AIServiceFormat
    /// API Key
    var apiKey: String
    /// 自定义模型名称
    var customModel: String
    /// 自定义基础 URL
    var baseURL: String
    /// 提醒间隔（分钟）
    var reminderIntervalMinutes: Int
    /// 最后一次提醒的日期
    var lastReminderDate: Date?

    /// 默认配置
    static let `default` = AIConfig(
        enabled: false,
        serviceFormat: .openAI,  // 默认使用 OpenAI 格式
        apiKey: "",
        customModel: "",
        baseURL: "",
        reminderIntervalMinutes: 120,
        lastReminderDate: nil
    )

    /// 实际使用的模型名称（优先级：自定义模型 > 默认模型）
    var effectiveModel: String {
        if !customModel.isEmpty {
            return customModel
        }
        return serviceFormat.defaultModel
    }

    /// 实际使用的基础 URL（优先级：自定义 URL > 默认 URL）
    var effectiveBaseURL: String {
        if !baseURL.isEmpty {
            return baseURL
        }
        return serviceFormat.defaultBaseURL
    }

    /// 验证提醒间隔的有效性，确保不小于 1 分钟
    mutating func validateReminderInterval() {
        if reminderIntervalMinutes < 1 {
            reminderIntervalMinutes = 1
        }
    }

    /// 检查是否应该发送关怀提醒
    func shouldSendReminder(currentTime: Date = Date()) -> Bool {
        guard enabled else { return false }
        guard !apiKey.isEmpty else { return false }

        let intervalMinutes = Double(reminderIntervalMinutes)

        if let lastDate = lastReminderDate {
            let minutesSinceLastReminder = currentTime.timeIntervalSince(lastDate) / 60
            return minutesSinceLastReminder >= intervalMinutes
        } else {
            return true
        }
    }
}
