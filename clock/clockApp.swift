//
//  clockApp.swift
//  下班助手
//
//  一个简洁的 macOS 菜单栏应用，帮助你追踪工作时间和下班倒计时
//

import SwiftUI

extension View {
    /// 为窗口设置标识符
    func withWindowIdentifier(_ identifier: String) -> some View {
        self.background(WindowIdentifierSetter(identifier: identifier))
    }
}

/// 辅助视图，用于设置窗口标识符
struct WindowIdentifierSetter: NSViewRepresentable {
    let identifier: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.identifier = NSUserInterfaceItemIdentifier(identifier)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// 应用主入口
@main
struct clockApp: App {
    // 配置管理器
    @StateObject private var configManager: ConfigManager
    // 通知管理器
    @StateObject private var notificationManager: NotificationManager
    // 假期视图模型
    @StateObject private var holidayViewModel: HolidayViewModel
    // 倒计时视图模型
    @StateObject private var viewModel: CountdownViewModel
    // AI 关怀管理器
    @StateObject private var aiCareManager: AICareManager
    // 状态栏控制器
    @StateObject private var statusBarController = StatusBarController()
    // 应用代理
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let config = ConfigManager()
        let notification = NotificationManager()
        let holidayVM = HolidayViewModel(configManager: config)
        let aiCare = AICareManager()
        _configManager = StateObject(wrappedValue: config)
        _notificationManager = StateObject(wrappedValue: notification)
        _holidayViewModel = StateObject(wrappedValue: holidayVM)
        _aiCareManager = StateObject(wrappedValue: aiCare)
        _viewModel = StateObject(wrappedValue: CountdownViewModel(configManager: config, notificationManager: notification, holidayViewModel: holidayVM))
    }

    var body: some Scene {
        // 主窗口
        Window("下班助手", id: "main") {
            MainWindowView(
                viewModel: viewModel,
                configManager: configManager,
                holidayViewModel: holidayViewModel
            )
            .onAppear {
                // 隐藏 Dock 图标，只在状态栏显示
                NSApp.setActivationPolicy(.accessory)
                // 设置状态栏
                statusBarController.setupStatusBar(viewModel: viewModel)
            }
            .withWindowIdentifier("main")
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // 设置窗口
        Window("设置", id: "settings") {
            SettingsView(
                configManager: configManager,
                notificationManager: notificationManager,
                aiCareManager: aiCareManager
            )
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

/// 应用代理，处理 Dock 图标点击和首次启动
class AppDelegate: NSObject, NSApplicationDelegate {
    /// 应用启动完成时调用
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 首次启动时打开主窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.openMainWindow()
        }
    }

    /// 打开主窗口
    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // 尝试找到主窗口（通过标识符）
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // 如果窗口还没创建，再等一下
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    /// 处理 Dock 图标点击（当应用在 Dock 中时）
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openMainWindow()
        return true
    }
}
