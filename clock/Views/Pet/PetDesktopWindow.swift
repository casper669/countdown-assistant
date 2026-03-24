import Cocoa
import SwiftUI

class PetDesktopWindow: NSPanel {
    static let shared = PetDesktopWindow()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 400, y: 300, width: 300, height: 380),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setupDesktopWindow()
    }
    
    private func setupDesktopWindow() {
        // 透明无边框
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        // 桌面最高层级
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // ✅ 关闭所有自动布局 + 不裁切
        if let contentView = contentView {
            contentView.autoresizingMask = []
        }
        isMovableByWindowBackground = true
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true

        // 图层不裁切
        contentView?.wantsLayer = true
        contentView?.layer?.masksToBounds = false
    }
    
    func updateContentView() {
        let petView = PetWindowView()
            .environmentObject(PetManager.shared)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.clear)
        
        let host = NSHostingView(rootView: petView)
        host.wantsLayer = true
        host.layer?.masksToBounds = false
        host.autoresizingMask = [.width, .height]
        
        contentView = host
    }
    
    func updateWindowSize(w: CGFloat, h: CGFloat) {
        setFrame(NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: w,
            height: h
        ), display: true)
    }
}

// 显示宠物
extension PetDesktopWindow {
    static func show() {
        let window = shared
        window.updateContentView()
        window.makeKeyAndOrderFront(nil)
    }
}
