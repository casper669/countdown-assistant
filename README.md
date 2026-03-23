# 下班助手

一个简洁优雅的 macOS 菜单栏应用，帮助你追踪工作时间和下班倒计时。

![macOS](https://img.shields.io/badge/macOS-15.7+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 功能特性

### 核心功能
- ⏰ **实时倒计时** - 精确到秒的下班倒计时显示
- 📅 **周末倒计时** - 显示距离周末还有多久
- 🎉 **假期倒计时** - 自动获取国家法定节假日，显示下一个假期倒计时
- 🔔 **智能提醒** - 支持下班前提醒和午休前提醒
- 🌓 **暗黑模式** - 完美适配 macOS 浅色/深色主题

### 界面特点
- 🎯 **菜单栏显示** - 倒计时直接显示在菜单栏，一目了然
- 🖱️ **点击切换** - 点击菜单栏图标即可显示/隐藏主窗口
- 🎨 **现代设计** - 简洁美观的界面设计
- 🚫 **无 Dock 图标** - 不占用 Dock 空间，保持桌面整洁

### 自定义设置
- ⚙️ **工作时间配置** - 自定义上班、下班时间
- 🍱 **午休时间设置** - 配置午休开始时间和时长
- 🔔 **通知设置** - 自定义下班提醒和午休提醒的提前时间

## 系统要求

- macOS 15.7 或更高版本
- Apple Silicon 或 Intel 处理器

## 安装

1. 下载最新版本的 `.app` 文件
2. 将应用拖入"应用程序"文件夹
3. 首次打开时，可能需要在"系统设置 > 隐私与安全性"中允许运行

## 使用说明

### 首次使用

1. 启动应用后，菜单栏会显示倒计时时间
2. 点击菜单栏图标打开主窗口
3. 点击主窗口中的"设置"按钮配置工作时间

### 配置工作时间

1. 在主窗口点击"设置"按钮
2. 设置上班时间（如 09:00）
3. 设置下班时间（如 18:00）
4. 设置午休开始时间和时长
5. 设置会自动保存

### 配置通知提醒

1. 打开设置窗口
2. 启用"启用下班提醒"开关
3. 设置提前提醒时间（默认 30 分钟）
4. 启用"启用午休提醒"开关（可选）
5. 设置午休提前提醒时间（默认 10 分钟）

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI
- **架构**: MVVM
- **API**:
  - UserNotifications - 通知功能
  - NSStatusBar - 菜单栏集成
  - URLSession - 假期数据获取

## 项目结构

```
clock/
├── clockApp.swift              # 应用入口
├── Models/                     # 数据模型
│   ├── WorkTimeConfig.swift    # 工作时间配置
│   ├── WorkDayStatus.swift     # 工作日状态
│   ├── Holiday.swift           # 假期模型
│   └── AIConfig.swift          # AI 配置模型
├── ViewModels/                 # 视图模型
│   ├── CountdownViewModel.swift    # 倒计时视图模型
│   └── HolidayViewModel.swift      # 假期视图模型
├── Views/                      # 视图
│   ├── MainWindowView.swift    # 主窗口
│   ├── SettingsView.swift      # 设置窗口
│   └── MenuBarView.swift       # 菜单栏视图
├── Services/                   # 服务层
│   ├── ConfigManager.swift         # 配置管理
│   ├── NotificationManager.swift   # 通知管理
│   ├── CountdownCalculator.swift   # 倒计时计算
│   ├── HolidayAPIService.swift     # 假期 API 服务
│   ├── AIAPIService.swift          # AI API 服务
│   └── AICareManager.swift         # AI 关怀管理器
└── StatusBarController.swift   # 状态栏控制器
```

## 开发

### 环境要求

- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

### 构建步骤

1. 克隆仓库
```bash
git clone https://github.com/casper669/countdown-assistant.git
cd countdown-assistant
```

2. 打开项目
```bash
open clock.xcodeproj
```

3. 在 Xcode 中选择目标设备并运行（⌘R）

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 致谢

- 假期数据来源：[中国法定节假日 API](https://timor.tech/api/holiday)
- 图标使用 SF Symbols

## 更新日志

### v1.0.0 (2026-03-20)
- 🎉 首次发布
- ⏰ 实时下班倒计时
- 📅 周末和假期倒计时
- 🔔 下班和午休提醒
- ⚙️ 自定义工作时间配置
