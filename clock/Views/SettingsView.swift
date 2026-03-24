//
//  SettingsView.swift
//  下班助手
//
//  设置视图，提供工作时间、通知、AI 关怀等配置界面
//

import SwiftUI

/// 设置视图，提供工作时间、通知、AI 关怀等配置界面
struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var aiCareManager: AICareManager
    @ObservedObject var petManager: PetManager

    init(
        configManager: ConfigManager,
        notificationManager: NotificationManager,
        aiCareManager: AICareManager,
        petManager: PetManager = PetManager.shared
    ) {
        self.configManager = configManager
        self.notificationManager = notificationManager
        self.aiCareManager = aiCareManager
        self.petManager = petManager
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 标题栏
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)

                    Text("设置")
                        .font(.system(size: 24, weight: .bold))

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 24)

                Divider()

                ScrollView {
                    VStack(spacing: 20) {
                        // 工作时间
                        SettingGroup(title: "工作时间", icon: "briefcase.fill", iconColor: .blue) {
                            VStack(spacing: 16) {
                                SettingRow(label: "上班时间", icon: "sunrise.fill", iconColor: .orange) {
                                    TimePickerField(
                                        time: Binding(
                                            get: { configManager.config.startTime },
                                            set: { newValue in
                                                configManager.config.startTime = newValue
                                            }
                                        ),
                                        defaultValue: "09:00"
                                    )
                                }

                                SettingRow(label: "下班时间", icon: "sunset.fill", iconColor: .blue) {
                                    TimePickerField(
                                        time: Binding(
                                            get: { configManager.config.endTime },
                                            set: { newValue in
                                                configManager.config.endTime = newValue
                                            }
                                        ),
                                        defaultValue: "18:00"
                                    )
                                }
                            }
                        }

                        // 午休时间
                        SettingGroup(title: "午休时间", icon: "cup.and.saucer.fill", iconColor: .green) {
                            VStack(spacing: 16) {
                                SettingRow(label: "午休开始", icon: "clock.fill", iconColor: .green) {
                                    TimePickerField(
                                        time: Binding(
                                            get: { configManager.config.lunchStart },
                                            set: { newValue in
                                                configManager.config.lunchStart = newValue
                                            }
                                        ),
                                        defaultValue: "12:00"
                                    )
                                }

                                SettingRow(label: "午休时长", icon: "timer", iconColor: .green) {
                                    HStack(spacing: 8) {
                                        TextField("90", value: $configManager.config.lunchDuration, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                        Text("分钟")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }
                            }
                        }

                        // 通知设置
                        SettingGroup(title: "通知提醒", icon: "bell.fill", iconColor: .red) {
                            VStack(spacing: 16) {
                                HStack {
                                    HStack(spacing: 10) {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 14))
                                        Text("启用下班提醒")
                                            .font(.system(size: 14))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $notificationManager.notificationsEnabled)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                }

                                SettingRow(label: "提前提醒", icon: "clock.badge.exclamationmark", iconColor: .orange) {
                                    HStack(spacing: 8) {
                                        TextField("30", value: $notificationManager.reminderMinutes, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                            .disabled(!notificationManager.notificationsEnabled)
                                        Text("分钟")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }

                                Divider()

                                HStack {
                                    HStack(spacing: 10) {
                                        Image(systemName: "fork.knife")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                        Text("启用午休提醒")
                                            .font(.system(size: 14))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $notificationManager.lunchReminderEnabled)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                }

                                SettingRow(label: "提前提醒", icon: "clock.badge.exclamationmark", iconColor: .green) {
                                    HStack(spacing: 8) {
                                        TextField("10", value: $notificationManager.lunchReminderMinutes, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                            .disabled(!notificationManager.lunchReminderEnabled)
                                        Text("分钟")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }
                            }
                        }

                        // AI 关怀助手
                        SettingGroup(title: "AI 关怀助手", icon: "brain.head.profile.fill", iconColor: .purple) {
                            VStack(spacing: 16) {
                                HStack {
                                    HStack(spacing: 10) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.purple)
                                            .font(.system(size: 14))
                                        Text("启用 AI 关怀")
                                            .font(.system(size: 14))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $aiCareManager.config.enabled)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                }

                                SettingRow(label: "API 格式", icon: "server.rack", iconColor: .blue) {
                                    Picker("选择格式", selection: $aiCareManager.config.serviceFormat) {
                                        ForEach(AIServiceFormat.allCases) { format in
                                            Text(format.displayName)
                                                .tag(format)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 200)
                                    .disabled(!aiCareManager.config.enabled)
                                    .onChange(of: aiCareManager.config.serviceFormat) { oldValue, newValue in
                                        var updatedConfig = aiCareManager.config
                                        updatedConfig.customModel = ""
                                        updatedConfig.baseURL = ""
                                        aiCareManager.config = updatedConfig
                                    }
                                }

                                SettingRow(label: "API Key", icon: "key.fill", iconColor: .blue) {
                                    SecureField(aiCareManager.config.serviceFormat.apiKeyPlaceholder, text: $aiCareManager.config.apiKey)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 250)
                                        .disabled(!aiCareManager.config.enabled)
                                }

                                SettingRow(label: "模型名称", icon: "cube.fill", iconColor: .orange) {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        TextField("", text: $aiCareManager.config.customModel, prompt: Text(aiCareManager.config.serviceFormat.defaultModel))
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 200)
                                            .disabled(!aiCareManager.config.enabled)
                                        if aiCareManager.config.customModel.isEmpty {
                                            Text("默认: \(aiCareManager.config.serviceFormat.defaultModel)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                SettingRow(label: "Base URL", icon: "link", iconColor: .blue) {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        TextField("", text: $aiCareManager.config.baseURL, prompt: Text(aiCareManager.config.serviceFormat.defaultBaseURL))
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 200)
                                            .disabled(!aiCareManager.config.enabled)
                                        if aiCareManager.config.baseURL.isEmpty {
                                            Text("默认: \(aiCareManager.config.serviceFormat.defaultBaseURL)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                    }
                                }

                                SettingRow(label: "提醒间隔", icon: "clock.arrow.circlepath", iconColor: .green) {
                                    HStack(spacing: 8) {
                                        TextField("120", value: $aiCareManager.config.reminderIntervalMinutes, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                            .disabled(!aiCareManager.config.enabled)
                                            .onChange(of: aiCareManager.config.reminderIntervalMinutes) { oldValue, newValue in
                                                if newValue < 1 {
                                                    DispatchQueue.main.async {
                                                        aiCareManager.config.reminderIntervalMinutes = 1
                                                    }
                                                }
                                            }
                                        Text("分钟（最小1分钟）")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }

                                // 测试按钮
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        aiCareManager.testConfiguration()
                                    }) {
                                        HStack(spacing: 8) {
                                            if aiCareManager.isTesting {
                                                ProgressView()
                                                    .controlSize(.small)
                                            }
                                            Image(systemName: "paperplane.fill")
                                            Text("测试配置")
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(aiCareManager.config.enabled && !aiCareManager.config.apiKey.isEmpty ? 0.2 : 0.1))
                                        )
                                        .foregroundColor(aiCareManager.config.enabled && !aiCareManager.config.apiKey.isEmpty ? .blue : .secondary)
                                    }
                                    .disabled(!aiCareManager.config.enabled || aiCareManager.config.apiKey.isEmpty || aiCareManager.isTesting)
                                    .buttonStyle(PlainButtonStyle())
                                    Spacer()
                                }

                                // 测试结果
                                if let testResult = aiCareManager.testResult {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: testResult.hasPrefix("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(testResult.hasPrefix("✅") ? .green : .red)
                                                .font(.system(size: 16))
                                            Text(testResult.hasPrefix("✅") ? "连接成功" : "连接失败")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(testResult.hasPrefix("✅") ? .green : .red)
                                            Spacer()
                                        }

                                        if let range = testResult.range(of: "\n\n"), let resultIndex = testResult.index(range.upperBound, offsetBy: 0, limitedBy: testResult.endIndex) {
                                            let apiResult = String(testResult[resultIndex...])
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("API 返回结果")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                Text(apiResult)
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(nil)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .frame(width: 350)
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color(nsColor: .textBackgroundColor))
                                            )
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(nsColor: .textBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(lineWidth: 1)
                                            .foregroundColor(Color(testResult.hasPrefix("✅") ? .green.opacity(0.3) : .red.opacity(0.3)))
                                    )
                                }

                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 12))
                                    Text("AI 关怀助手会在工作时间发送温馨提醒，帮助你保持健康的工作习惯")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        // 虚拟宠物设置
                        SettingGroup(title: "虚拟宠物", icon: "pawprint.fill", iconColor: .pink) {
                            VStack(spacing: 16) {
                                HStack {
                                    HStack(spacing: 10) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.pink)
                                            .font(.system(size: 14))
                                        Text("启用虚拟宠物")
                                            .font(.system(size: 14))
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { petManager.config.enabled },
                                        set: { newValue in
                                            var updatedConfig = petManager.config
                                            updatedConfig.enabled = newValue
                                            petManager.updateConfig(updatedConfig)
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                }

                                SettingRow(label: "宠物类型", icon: "person.fill", iconColor: .orange) {
                                    Picker("选择宠物", selection: Binding(
                                        get: { petManager.config.petType },
                                        set: { newValue in
                                            var updatedConfig = petManager.config
                                            updatedConfig.petType = newValue
                                            petManager.updateConfig(updatedConfig)
                                        }
                                    )) {
                                        ForEach(PetType.allCases) { type in
                                            Text(type.displayName)
                                                .tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 200)
                                }

                                SettingRow(label: "自动隐藏", icon: "timer", iconColor: .green) {
                                    HStack(spacing: 8) {
                                        TextField("15", value: Binding(
                                            get: { petManager.config.autoHideDelay },
                                            set: { newValue in
                                                var updatedConfig = petManager.config
                                                updatedConfig.autoHideDelay = newValue
                                                petManager.updateConfig(updatedConfig)
                                            }
                                        ), format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                        Text("秒")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }

                                SettingRow(label: "窗口透明度", icon: "opacity", iconColor: .purple) {
                                    HStack(spacing: 8) {
                                        TextField("0.95", value: Binding(
                                            get: { petManager.config.windowOpacity },
                                            set: { newValue in
                                                var updatedConfig = petManager.config
                                                updatedConfig.windowOpacity = newValue
                                                petManager.updateConfig(updatedConfig)
                                            }
                                        ), format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                        Text("(0.5-1.0)")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }

                                // 测试宠物弹窗按钮
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        petManager.showPet(withMessage: "你好！我是你的虚拟宠物助手，工作累了吗？记得站起来活动一下哦！")
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "play.fill")
                                            Text("测试宠物弹窗")
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.pink.opacity(0.2))
                                        )
                                        .foregroundColor(.pink)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(!petManager.config.enabled)
                                    Spacer()
                                }

                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 12))
                                    Text("虚拟宠物会在需要发送关怀提醒时自动出现，点击可互动")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        // 提示信息
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("设置会自动保存")
                                    .font(.system(size: 13, weight: .medium))
                                Text("时间格式：HH:mm（如 09:00）")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.08))
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                }
            }
        }
        .frame(width: 520, height: 950)
    }
}

/// 设置组组件，用于将相关设置分组显示
struct SettingGroup<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }

            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

/// 设置行组件，用于显示单个设置项
struct SettingRow<Content: View>: View {
    let label: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(label: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .frame(width: 90, alignment: .leading)

            Spacer()

            content
        }
    }
}
