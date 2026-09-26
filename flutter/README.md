# 薄肌俱乐部 Flutter 版

Flutter 版本用于在 Windows、Web、Android 和 iOS 上快速预览和迭代。后端继续使用现有 Node.js + MariaDB + DeepSeek API。

## 当前功能

- 手机号 + 验证码登录。
- 身体和训练条件建档。
- AI 生成训练计划。
- 文字导入训练计划。
- 自由训练入口。
- 6 元 / 12 个月 Apple 自动续费会员。
- 恢复购买。
- 本地通知授权。
- 个人中心和会员状态。
- 无双人、搭档或离线模式。

## Windows 快速查看

安装 Flutter Stable 后：

```powershell
cd outputs\boji-flutter
flutter create --platforms=web,android,ios .
flutter pub get
flutter run -d chrome
```

常用命令：

```powershell
flutter analyze
flutter test
flutter run -d windows
flutter devices
```

## 生成 iOS/Android 平台目录

```powershell
flutter create --platforms=ios,android,web .
```

不要删除 `lib/` 和 `pubspec.yaml`。`flutter create` 只补齐平台工程。

## 后端接口

```text
POST /api/auth/sms/send
POST /api/auth/sms/verify
GET  /api/me
POST /api/onboarding
POST /api/auth/logout
POST /api/push-token
POST /api/billing/apple/verify
POST /api/plan/generate
POST /api/plan/import
POST /api/plan/version
```

后端模块仍使用 `boji-ios/Backend` 中的：

- 手机短信。
- Apple 交易验证。
- 会员记录。
- 推送 Token。
- 数据库迁移。

## Apple 上架

Flutter 仍需要 Mac 或云端 Mac 完成：

- Xcode 签名。
- TestFlight。
- App Store Connect。
- Apple 真实购买。
- APNs。
- App Store 审核。

Windows 可以完成：

- UI 开发。
- 热重载。
- Web/Windows/Android 预览。
- Dart 单元测试。
- 后端接口测试。
- Flutter 静态分析。

## 当前状态

已完成 Flutter 客户端源码和 Windows/Web 开发入口。运行前需要在本机安装 Flutter SDK，并通过 `flutter analyze` 和 `flutter test` 完成编译验证。
