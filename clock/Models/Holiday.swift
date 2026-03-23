//
//  Holiday.swift
//  下班助手
//
//  节假日模型，包含节假日名称、日期和是否放假的信息
//

import Foundation

/// 节假日模型，包含节假日名称、日期和是否放假的信息
struct Holiday: Codable, Identifiable {
    let id = UUID()
    /// 节假日名称
    let name: String
    /// 日期（格式：yyyy-MM-dd，如 "2026-01-01"）
    let date: String
    /// 是否放假（true=放假）
    let isOffDay: Bool

    enum CodingKeys: String, CodingKey {
        case name, date, isOffDay
    }

    /// 转换日期字符串为 Date 对象
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}
