//
//  ConfigManager.swift
//  下班助手
//
//  配置管理器，负责工作时间配置的加载和保存
//

import Foundation
import Combine

/// 配置管理器，负责工作时间配置的加载和保存
class ConfigManager: ObservableObject {
    /// 当前工作时间配置（通过 @Published 实现响应式更新）
    @Published var config: WorkTimeConfig {
        didSet {
            save()
        }
    }

    private let userDefaultsKey = "workTimeConfig"

    /// 初始化方法，从 UserDefaults 加载配置
    init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(WorkTimeConfig.self, from: data) {
            self.config = decoded
            print("📝 加载配置:")
            print("   上班: \(decoded.startTime), 下班: \(decoded.endTime)")
        } else {
            self.config = .default
            print("📝 使用默认配置:")
            print("   上班: \(WorkTimeConfig.default.startTime), 下班: \(WorkTimeConfig.default.endTime)")
        }
    }

    /// 保存配置到 UserDefaults
    private func save() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}
