//
//  MenuBarView.swift
//  下班助手
//
//  菜单栏视图，显示在系统菜单栏的下拉菜单
//

import SwiftUI

/// 菜单栏视图，显示在系统菜单栏的下拉菜单
struct MenuBarView: View {
    @ObservedObject var viewModel: CountdownViewModel
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var holidayViewModel: HolidayViewModel
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.openWindow) private var openWindow
    @State private var currentTime = Date()

    var body: some View {
        VStack(spacing: 0) {
            // 状态头部
            VStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: statusIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                    .shadow(color: statusColor.opacity(0.5), radius: 8, x: 0, y: 4)

                Text(viewModel.status.displayText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(nsColor: .labelColor))

                Text(currentTimeString)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(nsColor: .labelColor))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(statusColor.opacity(0.12))

            Divider()

            // 倒计时显示
            if viewModel.status == .working || viewModel.status == .lunch {
                VStack(spacing: 10) {
                    Text("距离下班")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))

                    Text(viewModel.displayText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.blue.opacity(0.08))
            } else {
                VStack(spacing: 10) {
                    Text(viewModel.displayText)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(statusColor.opacity(0.08))
            }

            Divider()

            // 周末和假期
            VStack(spacing: 0) {
                MenuInfoRow(
                    icon: "calendar",
                    iconColor: .purple,
                    label: "周末",
                    value: holidayViewModel.timeUntilWeekend
                )

                if let nextHoliday = holidayViewModel.nextHoliday {
                    Divider()
                        .padding(.leading, 16)

                    MenuInfoRow(
                        icon: "star.fill",
                        iconColor: .orange,
                        label: nextHoliday.name,
                        value: holidayViewModel.timeUntilNextHoliday
                    )
                }
            }

            Divider()

            // 工作时间
            VStack(alignment: .leading, spacing: 12) {
                Text("工作时间")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        Text("上班")
                            .font(.system(size: 14))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))

                        Spacer()

                        Text(configManager.config.startTime)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "sunset.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text("下班")
                            .font(.system(size: 14))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))

                        Spacer()

                        Text(configManager.config.endTime)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .frame(width: 24)

                        Text("午休")
                            .font(.system(size: 14))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))

                        Spacer()

                        Text("\(configManager.config.lunchDuration)分钟")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            .background(Color.primary.opacity(0.03))

            Divider()

            // 操作按钮
            VStack(spacing: 10) {
                Button(action: { openWindow(id: "main") }) {
                    HStack(spacing: 10) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 12))
                        Text("主界面")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: { openWindow(id: "settings") }) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                        Text("设置")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack(spacing: 10) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                        Text("退出")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(width: 300)
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            // 启动定时器更新当前时间
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }

    private var statusIcon: String {
        switch viewModel.status {
        case .working: return "briefcase.fill"
        case .lunch: return "fork.knife"
        case .beforeWork: return "sunrise.fill"
        case .afterWork: return "moon.stars.fill"
        case .weekend: return "beach.umbrella.fill"
        case .holiday: return "party.popper.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .working: return .blue
        case .lunch: return .orange
        case .beforeWork: return .gray
        case .afterWork: return .green
        case .weekend: return .purple
        case .holiday: return .red
        }
    }

    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
}

/// 菜单信息行组件，用于显示关键信息行
struct MenuInfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
