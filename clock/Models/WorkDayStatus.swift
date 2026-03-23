//
//  WorkDayStatus.swift
//  下班助手
//
//  工作日状态枚举，定义了一天中的不同工作阶段
//

import Foundation

/// 工作日状态枚举，定义了一天中的不同工作阶段
enum WorkDayStatus {
    case beforeWork      // 上班前
    case working         // 工作中
    case lunch           // 午休中
    case afterWork       // 已下班
    case weekend         // 周末
    case holiday         // 节假日

    /// 获取状态的显示文本
    var displayText: String {
        switch self {
        case .beforeWork: return "未上班"
        case .working: return "工作中"
        case .lunch: return "午休中"
        case .afterWork: return "已下班"
        case .weekend: return "周末"
        case .holiday: return "节假日"
        }
    }
}
