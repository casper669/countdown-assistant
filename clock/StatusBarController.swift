//
//  StatusBarController.swift
//  下班助手
//
//  状态栏控制器，管理菜单栏图标和点击事件
//

import AppKit
import SwiftUI
import Combine

/// 状态栏控制器，负责管理菜单栏的显示和交互
class StatusBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var viewModel: CountdownViewModel?

    /// 设置状态栏
    /// - Parameter viewModel: 倒计时视图模型
    func setupStatusBar(viewModel: CountdownViewModel) {
        self.viewModel = viewModel

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = viewModel.displayText
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }

        // 监听 viewModel 的变化来更新状态栏文字
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusBarText),
            name: NSNotification.Name("UpdateStatusBar"),
            object: nil
        )
    }

    /// 状态栏按钮点击事件，切换主窗口的显示/隐藏
    @objc private func statusBarButtonClicked() {
        // 激活应用
        NSApp.activate(ignoringOtherApps: true)

        // 查找主窗口，支持通过多种方式查找
        var mainWindow: NSWindow? = nil

        // 方法1：通过标识符查找（首选）
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            mainWindow = window
        }
        // 方法2：通过窗口标题查找（备选）
        else if let window = NSApp.windows.first(where: { $0.title.contains("下班助手") || $0.title == "下班倒计时" }) {
            mainWindow = window
        }
        // 方法3：取第一个可用窗口（兜底）
        else if let window = NSApp.windows.first {
            mainWindow = window
        }

        if let window = mainWindow {
            if window.isVisible {
                // 如果窗口可见，隐藏它
                window.orderOut(nil)
            } else {
                // 如果窗口隐藏，显示并置于最前
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                // 确保窗口位于所有应用程序之上
                window.level = .floating
            }
        } else {
            // 如果窗口不存在，尝试多次查找
            var attempts = 0
            let maxAttempts = 5

            func tryShowWindow() {
                attempts += 1

                // 再次尝试查找窗口
                var foundWindow: NSWindow? = nil
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                    foundWindow = window
                } else if let window = NSApp.windows.first(where: { $0.title.contains("下班助手") }) {
                    foundWindow = window
                } else if let window = NSApp.windows.first {
                    foundWindow = window
                }

                if let window = foundWindow {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    window.level = .normal
                } else if attempts < maxAttempts {
                    // 继续尝试
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tryShowWindow()
                    }
                } else {
                    // 最后尝试通过通知打开
                    NotificationCenter.default.post(name: NSNotification.Name("OpenMainWindow"), object: nil)
                }
            }

            tryShowWindow()
        }
    }

    /// 更新状态栏文字
    @objc private func updateStatusBarText() {
        if let button = statusItem?.button, let viewModel = viewModel {
            button.title = viewModel.displayText
        }
    }

    /// 手动更新状态栏文字
    /// - Parameter text: 要显示的文字
    func updateText(_ text: String) {
        if let button = statusItem?.button {
            button.title = text
        }
    }
}
