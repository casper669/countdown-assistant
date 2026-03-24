//
//  PetSpeechBubbleView.swift
//  下班助手
//
//  宠物对话框视图
//

import SwiftUI

/// 宠物对话框视图
struct PetSpeechBubbleView: View {
    let message: String
    let onClose: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 气泡主体
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .tracking(0.2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.trailing, 20)
                .frame(minWidth: 100, maxWidth: 200)
                .background(
                    ZStack {
                        // 模糊背景层（玻璃态效果）
                        RoundedRectangle(cornerRadius: 18)
                            .fill(bubbleBackground)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.8)
                            )

                        // 顶部高光
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.6),
                                        Color.white.opacity(0),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 40)
                            .offset(y: -20)

                        // 精致边框
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(borderGradient, lineWidth: 1.2)
                    }
                )
                .shadow(color: shadowColor.opacity(0.08), radius: 2, x: 0, y: 1)
                .shadow(color: shadowColor.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: shadowColor.opacity(0.06), radius: 16, x: 0, y: 8)

            // 关闭按钮
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    onClose()
                }
            }) {
                ZStack {
                    // 按钮背景
                    Circle()
                        .fill(closeButtonBackground)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    closeButtonBorder,
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 2, x: 0, y: 1)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 4, x: 0, y: 2)

                    // X 图标
                    Image(systemName: "xmark")
                        .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(colorScheme == .dark ? 0.9 : 0.5),
                                    Color.gray.opacity(colorScheme == .dark ? 0.7 : 0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(isPressed ? 0.9 : (isHovering ? 1.12 : 1.0))
                .opacity(isHovering ? 1.0 : 0.85)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .help("关闭")
            .offset(x: -5, y: -5)
            .onHover { hovering in
                isHovering = hovering
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
    }

    /// 文字颜色
    private var textColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.95)
            : Color(nsColor: NSColor(white: 0.12, alpha: 1))
    }

    /// 气泡背景
    private var bubbleBackground: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(nsColor: NSColor(white: 0.20, alpha: 0.95)),
                    Color(nsColor: NSColor(white: 0.16, alpha: 0.95))
                ]
                : [
                    Color.white.opacity(0.95),
                    Color(nsColor: NSColor(white: 0.97, alpha: 0.95))
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 边框渐变
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.05)
                ]
                : [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.blue.opacity(0.15)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 阴影颜色
    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.8)
            : Color.black.opacity(0.25)
    }

    /// 关闭按钮背景
    private var closeButtonBackground: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color.white.opacity(0.18),
                    Color.white.opacity(0.12)
                ]
                : [
                    Color.white.opacity(0.98),
                    Color(nsColor: NSColor(white: 0.96, alpha: 0.98))
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 关闭按钮边框
    private var closeButtonBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.25)
            : Color.gray.opacity(0.2)
    }
}

// MARK: - Preview

struct PetSpeechBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 40) {
                PetSpeechBubbleView(message: "下班啦！", onClose: {})
                PetSpeechBubbleView(message: "工作累了吗？记得休息～", onClose: {})
                PetSpeechBubbleView(message: "工作累了吗？记得站起来活动一下，喝杯水哦！", onClose: {})
                PetSpeechBubbleView(message: "已经工作2小时了，该休息一下啦～眼睛也要放松放松，看看远处的风景吧！", onClose: {})
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")

            VStack(spacing: 40) {
                PetSpeechBubbleView(message: "下班啦！", onClose: {})
                PetSpeechBubbleView(message: "工作累了吗？记得休息～", onClose: {})
                PetSpeechBubbleView(message: "工作累了吗？记得站起来活动一下，喝杯水哦！", onClose: {})
                PetSpeechBubbleView(message: "已经工作2小时了，该休息一下啦～眼睛也要放松放松，看看远处的风景吧！", onClose: {})
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
