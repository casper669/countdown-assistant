//
//  MainWindowView.swift
//  下班助手
//
//  主窗口视图，显示工作状态、倒计时和重要信息
//

import SwiftUI

/// 窗口关闭监听器
struct WindowCloseMonitor: NSViewRepresentable {
    let onClose: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.window = window
                NotificationCenter.default.addObserver(
                    context.coordinator,
                    selector: #selector(Coordinator.windowWillClose(_:)),
                    name: NSWindow.willCloseNotification,
                    object: window
                )
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }

    class Coordinator {
        let onClose: () -> Void
        weak var window: NSWindow?

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        @objc func windowWillClose(_ notification: Notification) {
            onClose()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

/// 主窗口视图，显示工作状态、倒计时和重要信息
struct MainWindowView: View {
    @ObservedObject var viewModel: CountdownViewModel
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var holidayViewModel: HolidayViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var isAnimating = false
    @State private var currentTime = Date()

    // 添加一个静态变量来跟踪是否是首次启动
    static var isFirstLaunch = true

    var body: some View {
        ZStack {
            // 背景
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // 顶部状态栏
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: statusIcon)
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        )
                        .shadow(color: statusColor.opacity(0.4), radius: 10, x: 0, y: 4)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.status.displayText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text(currentTimeString)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // 主倒计时卡片
                if viewModel.status == .working || viewModel.status == .lunch {
                    VStack(spacing: 12) {
                        Text("距离下班还有")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(viewModel.displayText)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        Text(viewModel.displayText)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(statusColor.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(statusColor.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }

                // 周末和假期卡片
                HStack(spacing: 12) {
                    // 周末倒计时
                    InfoCard(
                        icon: "calendar",
                        iconColor: .purple,
                        title: "周末",
                        value: holidayViewModel.timeUntilWeekend
                    )

                    // 假期倒计时
                    if let nextHoliday = holidayViewModel.nextHoliday {
                        InfoCard(
                            icon: "star.fill",
                            iconColor: .orange,
                            title: nextHoliday.name,
                            value: holidayViewModel.timeUntilNextHoliday
                        )
                    }
                }
                .padding(.horizontal, 24)

                // 工作时间信息
                HStack(spacing: 12) {
                    SmallInfoCard(
                        icon: "sunrise.fill",
                        iconColor: .orange,
                        label: "上班",
                        value: configManager.config.startTime
                    )

                    SmallInfoCard(
                        icon: "sunset.fill",
                        iconColor: .blue,
                        label: "下班",
                        value: configManager.config.endTime
                    )

                    SmallInfoCard(
                        icon: "cup.and.saucer.fill",
                        iconColor: .green,
                        label: "午休",
                        value: "\(configManager.config.lunchDuration)分"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // 底部按钮
                HStack(spacing: 10) {
                    Button(action: { openWindow(id: "settings") }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                            Text("设置")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                            Text("退出")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 480, height: 580)
        .background(
            WindowCloseMonitor {
                // 主窗口关闭时，同时关闭设置窗口
                if let settingsWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "settings" }) {
                    settingsWindow.close()
                }
            }
        )
        .onAppear {
            isAnimating = true

            // 启动定时器更新当前时间
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }

            // 首次启动时自动显示窗口
            if MainWindowView.isFirstLaunch {
                MainWindowView.isFirstLaunch = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.activate(ignoringOtherApps: true)
                    // 通过多种方式查找窗口
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                    } else if let window = NSApp.windows.first(where: { $0.title.contains("下班") }) {
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                    } else if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMainWindow"))) { _ in
            openWindow(id: "main")
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

/// 信息卡片组件，用于显示重要信息（如周末倒计时）
struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(iconColor)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(iconColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
    }
}

/// 小信息卡片组件，用于显示工作时间信息
struct SmallInfoCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
}
