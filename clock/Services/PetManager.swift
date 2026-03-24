//
//  PetManager.swift
//  下班助手
//
//  虚拟宠物管理器，负责管理宠物窗口的显示和隐藏
//

import Foundation
import Combine
import SwiftUI

class PetManager: ObservableObject {
    static let shared = PetManager()

    @Published var config: PetConfig
    @Published var isPetVisible: Bool = false
    @Published var currentMessage: String = ""

    private var window: NSWindow?
    private var timer: Timer?

    private let userDefaultsKey = "petConfig"

    /// 初始化方法
    private init() {
        // 从 UserDefaults 加载配置
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(PetConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = .default
        }
    }

    /// 显示宠物
    /// - Parameters:
    ///   - message: 显示的消息
    func showPet(withMessage message: String) {
        print("🐾 showPet 被调用")
        print("   - 消息: \(message)")
        print("   - enabled: \(config.enabled)")
        print("   - 当前窗口: \(window != nil ? "存在" : "不存在")")

        guard config.enabled else {
            print("❌ 宠物功能未启用")
            return
        }

        currentMessage = message
        isPetVisible = true

        if window == nil {
            print("🐾 创建新窗口...")
            createPetWindow()
        } else {
            print("🐾 使用已有窗口")
        }

        // 显示窗口
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        print("🐾 窗口显示命令已执行")
        print("   - 窗口可见: \(window?.isVisible ?? false)")

        // 启动自动隐藏定时器
        startAutoHideTimer()
    }

    /// 隐藏宠物
    func hidePet() {
        window?.orderOut(nil)
        isPetVisible = false
        stopAutoHideTimer()
    }

    /// 创建宠物窗口
    private func createPetWindow() {
        let petView = PetWindowView()
            .environmentObject(self)

        // 固定窗口尺寸
        let width: CGFloat = 280
        let height: CGFloat = 340

        // 获取主屏幕可用区域（排除菜单栏和 Dock）
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        // 生成随机位置，确保窗口完全在屏幕内
        let margin: CGFloat = 20  // 距离屏幕边缘的最小距离
        let maxX = screenFrame.maxX - width - margin
        let minX = screenFrame.minX + margin
        let maxY = screenFrame.maxY - height - margin
        let minY = screenFrame.minY + margin

        let x = CGFloat.random(in: minX...maxX)
        let y = CGFloat.random(in: minY...maxY)

        let window = NSWindow(
            contentRect: NSRect(
                x: x,
                y: y,
                width: width,
                height: height
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 完全透明背景
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.isMovableByWindowBackground = false
        window.hasShadow = false
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        window.identifier = .init("petWindow")
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true

        let hostingView = NSHostingView(rootView: petView)
        window.contentView = hostingView

        self.window = window

        // 强制显示窗口
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        print("🐾 窗口创建完成")
        print("   - 窗口位置: \(window.frame)")
        print("   - 窗口可见: \(window.isVisible)")
        print("   - 窗口层级: \(window.level.rawValue)")
    }

    /// 启动自动隐藏定时器
    private func startAutoHideTimer() {
        stopAutoHideTimer()
        timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(config.autoHideDelay),
            repeats: false
        ) { [weak self] _ in
            self?.hidePet()
        }
    }

    /// 停止自动隐藏定时器
    private func stopAutoHideTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// 移动宠物窗口
    func movePet(to position: CGPoint) {
        guard let window = window else { return }

        window.setFrameTopLeftPoint(position)

        var updatedConfig = config
        updatedConfig.savePosition(position)
        config = updatedConfig
        saveConfig()
    }

    /// 更新配置
    func updateConfig(_ newConfig: PetConfig) {
        var updatedConfig = newConfig
        updatedConfig.validateConfig()
        self.config = updatedConfig
        saveConfig()
    }

    /// 保存配置到 UserDefaults
    private func saveConfig() {
        do {
            let encoded = try JSONEncoder().encode(config)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("保存宠物配置失败: \(error)")
        }
    }

    /// 获取宠物位置
    func getPetPosition() -> CGPoint {
        if let window = window {
            return window.frame.origin
        }
        return config.petPosition
    }

    /// 重置自动隐藏定时器
    func resetAutoHideTimer() {
        startAutoHideTimer()
    }
}

// MARK: - NSWindow 扩展

extension NSWindow {
    /// 设置窗口左上角位置
    func setFrameTopLeftPoint(_ point: CGPoint) {
        let frame = NSRect(
            origin: point,
            size: self.frame.size
        )
        self.setFrame(frame, display: true)
    }

    /// 获取窗口左上角位置
    var topLeftPoint: CGPoint {
        self.frame.origin
    }
}

// MARK: - 便捷访问属性

extension PetManager {
    /// 宠物位置
    var petPosition: CGPoint {
        get {
            config.petPosition
        }
        set {
            var updatedConfig = config
            updatedConfig.savePosition(newValue)
            config = updatedConfig
            saveConfig()
        }
    }
}
