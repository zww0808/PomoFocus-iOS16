# 仅 Windows + 已安装 TrollStore 的 iPhone：构建和安装 PomoFocus

## 准备
- Windows 电脑和浏览器
- 免费 GitHub 账号（https://github.com）
- iPhone 具备正常运行的 TrollStore，系统为 iOS 16.0–16.6.1 等官方支持版本

## 第一步：将工程上传 GitHub
1. 在 Windows 上解压本 ZIP，进入 `PomoFocus-iOS16` 文件夹。
2. 登录 GitHub → New repository → 仓库名 `PomoFocus-iOS16` → 选 Public → Create repository。公开仓库中的标准 GitHub-hosted Actions 运行免费。注意公开仓库源代码对所有人可见。
3. 进入该仓库 → `uploading an existing file` 或 `Add file` → `Upload files`。
4. **将工程目录里的内容上传到仓库根目录**：`PomoFocus/`、`PomoFocus.xcodeproj/`、`.github/workflows/build-ios16-ipa.yml`、`scripts/`、README 等，保留文件夹层级。注意 `.github` 是隐藏文件夹，Windows 资源管理器需要开启“显示隐藏项目”。如果网页不接受文件夹，推荐安装 GitHub Desktop（https://desktop.github.com/），通过 GitHub Desktop 新建仓库并发布整个工程目录。
5. 提交 `Commit changes`，确保仓库根目录直接有 `PomoFocus.xcodeproj`，不是多套一层 `PomoFocus-iOS16`。

## 第二步：云端编译
1. 打开仓库顶部 `Actions`。
2. 左侧选择 `Build iOS 16 TrollStore IPA`。
3. 点击 `Run workflow` → 再点绿色 `Run workflow`。（上传代码到 main 分支也会自动执行。）
4. 打开完成的工作流运行记录，确认 `build` 为绿色对勾。如红色失败，展开失败步骤并保存日志。
5. 页面底部 `Artifacts` 中下载 `PomoFocus-iOS16-TrollStore-IPA` ZIP。
6. 解压 ZIP，得到 `PomoFocus-iOS16-TrollStore.ipa`。

## 第三步：在 iPhone 安装
1. 用数据线、iCloud Drive 或局域网文件传输，将 IPA 复制到 iPhone “文件” App。
2. 在 iPhone “文件” App 点 IPA，使用共享菜单“在 TrollStore 中打开”；也可在 TrollStore 中点击 `+` 选择 IPA。
3. 等待安装后从主屏幕启动，首次通知授权选择允许。

## 注意事项
- IPA **必须在 GitHub Actions 的 Mac 构建成功后才会生成**。本 ZIP 是源码而非已编译 IPA。
- GitHub Actions 的产物下载本身是 ZIP，**需解压取得内部 IPA**，不要将 Actions 下载 ZIP 直接当 IPA。
- 工作流生成的是 ad-hoc 签名 IPA，面向 TrollStore，不是 App Store 或普通未越狱设备通用安装包。
- 该流程尚未在云端实际编译和实机安装验证；若 TrollStore 报签名错误，可尝试更新 TrollStore 或提供错误信息再排查。
- 如需保密代码，可选 Private 仓库，但可能消耗 GitHub Actions 配额或产生费用。
