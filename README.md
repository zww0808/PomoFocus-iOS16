# 专注番茄 PomoFocus · iOS 16+

原生 SwiftUI 番茄钟：专注/短休息/长休息、暂停重置跳过、时长设置、自动切换、本地通知、7 日统计、完成记录。数据仅保存于设备，不需要网络。

## 打包 IPA（需要 Mac + Xcode 14.3 或更高版本）

1. 解压工程，在 Mac 上打开 `PomoFocus.xcodeproj`，选择 PomoFocus scheme，目标为 Any iOS Device (arm64)。
2. 在 Terminal 进入工程目录，执行 `bash scripts/build_ipa_mac.sh`。
3. 输出文件：`dist/PomoFocus-iOS16-unsigned.ipa`。该文件内含真正由 Xcode 编译的 arm64 App，**不是纯压缩包伪装 IPA**。
4. 将 IPA 传到已安装 TrollStore 的手机，使用 TrollStore 的加号选择 IPA 进行安装。

**注意：** 未签名 IPA 是否能由 TrollStore 成功安装与机型、设备系统和 TrollStore 实际状态有关；部分设备可能需要对编译出的 App 做适当签名处理，不能保证一定直装。本工程未申请特殊权限。

## 功能注意

- 最低部署版本 iOS 16.0，适配 iPhone，暗色主题。
- 计时采用 `Date` 绝对截止时间；切到后台或锁屏后不依赖持续后台计时。
- 结束时使用系统本地通知。第一次需要允许通知。
- iOS 不保证 App 被关闭后还会执行代码；重新打开时会补算结束状态。自动进入下一阶段仅能在 App 实际运行时自动启动，不代表可在强制退出后连续后台运行。
- 如已有其他应用使用 `com.pomofocus.offline` 标识符，可在 Xcode 中更改 Bundle Identifier。

## 环境限制

工程是在 Linux 环境生成，未能在 iOS SDK 下进行实际编译或真机测试；IPA 必须在 Mac/Xcode 环境中生成。


## 无 Mac 用户（Windows + TrollStore）

本版本新增 GitHub Actions 云端 macOS 构建配置，参见 `WINDOWS-巨魔安装指南.md`。
