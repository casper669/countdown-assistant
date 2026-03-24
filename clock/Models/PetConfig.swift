//
//  PetConfig.swift
//  下班助手
//
//  虚拟宠物的配置模型
//

import Foundation
import AppKit

/// 宠物类型
enum PetType: String, Codable, CaseIterable, Identifiable {
    case robot     // 机器人
    case sphere    // 球体精灵
    case cube      // 方块精灵
    case custom    // 自定义

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .robot: return "机器人"
        case .sphere: return "球体精灵"
        case .cube: return "方块精灵"
        case .custom: return "自定义"
        }
    }

    /// 主色调
    var primaryColor: NSColor {
        switch self {
        case .robot: return .systemBlue
        case .sphere: return .systemPink
        case .cube: return .systemOrange
        case .custom: return .systemPurple
        }
    }
}

/// 虚拟宠物配置结构体
struct PetConfig: Codable {
    /// 是否启用虚拟宠物功能
    var enabled: Bool
    /// 宠物类型
    var petType: PetType
    /// 自动隐藏延迟（秒）
    var autoHideDelay: Int
    /// 窗口透明度
    var windowOpacity: Double
    /// 初始位置 X
    var initialPositionX: CGFloat
    /// 初始位置 Y
    var initialPositionY: CGFloat
    /// 最后显示的位置 X
    var lastPositionX: CGFloat?
    /// 最后显示的位置 Y
    var lastPositionY: CGFloat?

    /// 默认配置
    static let `default` = PetConfig(
        enabled: true,
        petType: .robot,
        autoHideDelay: 15,
        windowOpacity: 0.95,
        initialPositionX: 100,
        initialPositionY: 100,
        lastPositionX: nil,
        lastPositionY: nil
    )

    /// 获取宠物位置（优先使用最后位置，否则使用初始位置）
    var petPosition: CGPoint {
        CGPoint(
            x: lastPositionX ?? initialPositionX,
            y: lastPositionY ?? initialPositionY
        )
    }

    /// 保存位置
    mutating func savePosition(_ position: CGPoint) {
        lastPositionX = position.x
        lastPositionY = position.y
    }

    /// 验证配置的有效性
    mutating func validateConfig() {
        if autoHideDelay < 5 {
            autoHideDelay = 5
        }
        if autoHideDelay > 300 {
            autoHideDelay = 300
        }
        if windowOpacity < 0.5 {
            windowOpacity = 0.5
        }
        if windowOpacity > 1.0 {
            windowOpacity = 1.0
        }
    }
}
