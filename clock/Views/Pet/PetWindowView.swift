//
//  PetWindowView.swift
//  下班助手
//
//  虚拟宠物主窗口视图
//

import SwiftUI

/// 虚拟宠物主窗口视图
struct PetWindowView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var isDragging = false
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            // 对话气泡（包含关闭按钮）
            if !petManager.currentMessage.isEmpty {
                PetSpeechBubbleView(
                    message: petManager.currentMessage,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            petManager.hidePet()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
                .padding(.top, 16)
            }

            // 3D 宠物
            Pet3DView()
                .frame(width: 180, height: 180)
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
                .allowsHitTesting(false)

            Spacer()
        }
        .frame(width: getWindowWidth(), height: getWindowHeight())
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "petWindow" }) {
                        let newOrigin = CGPoint(
                            x: window.frame.origin.x + value.translation.width,
                            y: window.frame.origin.y - value.translation.height
                        )
                        window.setFrameOrigin(newOrigin)
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "petWindow" }) {
                        petManager.movePet(to: window.frame.origin)
                    }
                    petManager.resetAutoHideTimer()
                }
        )
    }

    private func getWindowWidth() -> CGFloat {
        return 280
    }

    private func getWindowHeight() -> CGFloat {
        return 340
    }
}

// MARK: - Preview
struct PetWindowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PetWindowView()
                .environmentObject(PetManager.shared)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
                .background(Color.gray.opacity(0.1))

            PetWindowView()
                .environmentObject(PetManager.shared)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
                .background(Color.gray.opacity(0.1))
        }
    }
}
