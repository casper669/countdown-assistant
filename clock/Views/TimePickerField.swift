//
//  TimePickerField.swift
//  下班助手
//
//  时间选择器组件
//

import SwiftUI

/// 时间选择器组件
struct TimePickerField: View {
    @Binding var time: String
    let defaultValue: String

    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0

    init(time: Binding<String>, defaultValue: String) {
        self._time = time
        self.defaultValue = defaultValue

        // 初始化选中的时间
        let initialTime = time.wrappedValue.isEmpty ? defaultValue : time.wrappedValue
        let (hour, minute) = Self.parseTime(initialTime)
        self._selectedHour = State(initialValue: hour)
        self._selectedMinute = State(initialValue: minute)
    }

    var body: some View {
        HStack(spacing: 4) {
            // 小时选择器
            Picker("", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d", hour))
                        .tag(hour)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 55)
            .onChange(of: selectedHour) { oldValue, newValue in
                updateTime()
            }

            Text(":")
                .foregroundColor(.secondary)

            // 分钟选择器
            Picker("", selection: $selectedMinute) {
                ForEach(0..<60, id: \.self) { minute in
                    Text(String(format: "%02d", minute))
                        .tag(minute)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 55)
            .onChange(of: selectedMinute) { oldValue, newValue in
                updateTime()
            }
        }
        .onAppear {
            // 确保有默认值
            if time.isEmpty {
                time = defaultValue
                let (hour, minute) = Self.parseTime(defaultValue)
                selectedHour = hour
                selectedMinute = minute
            } else {
                // 验证并修正格式
                let (hour, minute) = Self.parseTime(time)
                selectedHour = hour
                selectedMinute = minute
                updateTime()
            }
        }
    }

    /// 更新时间字符串
    private func updateTime() {
        time = String(format: "%02d:%02d", selectedHour, selectedMinute)
    }

    /// 解析时间字符串为小时和分钟
    private static func parseTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        let components = trimmed.split(separator: ":")

        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              hour >= 0 && hour < 24,
              minute >= 0 && minute < 60 else {
            // 解析失败，返回默认值 09:00
            return (9, 0)
        }

        return (hour, minute)
    }
}

// MARK: - Preview

struct TimePickerField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TimePickerField(
                time: .constant("09:00"),
                defaultValue: "09:00"
            )

            TimePickerField(
                time: .constant("18:00"),
                defaultValue: "18:00"
            )

            TimePickerField(
                time: .constant(""),
                defaultValue: "12:00"
            )
        }
        .padding()
    }
}
