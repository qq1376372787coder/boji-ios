# 薄肌俱乐部 iOS 原生版

这是基于 SwiftUI 的 iOS 17+ 项目工程源码，后端接口继续使用现有 Node.js 服务。

## 当前范围

- 手机号 + 短信验证码登录。
- 身体情况和训练条件建档。
- AI 生成训练计划。
- 文字导入训练计划。
- 自由训练入口。
- Apple App 内购买 6 元 / 12 个月自动续费会员。
- 恢复购买。
- 推送授权和 APNs Token 上传。
- 个人中心、会员状态、隐私入口。
- 不包含 Android。
- 不包含离线模式。
- 不包含双人/搭档功能。

## 目录

```text
project.yml                 XcodeGen 项目配置
Boji/
  BojiApp.swift             App 入口和 AppDelegate
  Config.swift              API 和商品 ID 配置
  Core/                     API、模型、Keychain、会话
  Services/                 StoreKit 2、APNs
  Features/                 SwiftUI 页面
Backend/
  migrations/               MariaDB 迁移
  lib/                      SMS、Apple 交易验证
  routes/                   手机登录、会员、推送接口
Docs/
  SETUP.md                  Mac、Xcode、Apple、后端配置
```

## 在 Mac 上生成 Xcode 工程

需要：

- macOS。
- Xcode 16 或更高版本。
- XcodeGen。

安装 XcodeGen：

```bash
brew install xcodegen
```

生成工程：

```bash
cd boji-ios
xcodegen generate
open Boji.xcodeproj
```

在 Xcode 中：

1. 选择 `Boji` target。
2. 在 Signing & Capabilities 中选择你的 Apple Developer Team。
3. 确认 Bundle ID：`cloud.gongxiang.boji`。
4. 如果 Bundle ID 被占用，修改 `project.yml`、`Config.swift` 和 App Store Connect 商品 ID。
5. 添加 App Icon。
6. 使用 iOS 17 模拟器或真机运行。

## 后端配置

在服务器 `.env` 中增加：

```env
SMS_PROVIDER=mock
SMS_PEPPER=replace-with-long-random-secret

APPLE_ENVIRONMENT=sandbox
APPLE_VERIFICATION_MODE=mock
APPLE_BUNDLE_ID=cloud.gongxiang.boji
APPLE_PRODUCT_ID=cloud.gongxiang.boji.annual12
APPLE_ISSUER_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY_PATH=/var/www/shuaqima-123/secrets/apple_api_key.p8
```

生产环境：

```env
SMS_PROVIDER=aliyun
SMS_ACCESS_KEY_ID=
SMS_ACCESS_KEY_SECRET=
SMS_SIGN_NAME=
SMS_TEMPLATE_CODE=
APPLE_ENVIRONMENT=production
APPLE_VERIFICATION_MODE=server
```

不要把 Apple 私钥、短信密钥或验证码写入日志。

## 数据库迁移

先备份数据库，再执行：

```bash
mysql -u DB_USER -p DB_NAME < Backend/migrations/20260926_ios_mobile.sql
```

## 需要接入现有 Node.js 项目

1. 复制 `Backend/lib/sms.mjs`、`Backend/lib/apple.mjs`。
2. 复制 `Backend/routes/mobile.mjs`。
3. 在 `server.mjs` 注册：

```js
import { registerMobileRoutes } from "./routes/mobile.mjs";

registerMobileRoutes(on);
```

建议放在现有路由注册之后，使手机登录和新版 `/api/onboarding` 逻辑覆盖旧入口。

4. 确认现有 `/api/plan/generate`、`/api/plan/import`、`/api/plan/version` 可供当前 iOS 客户端调用。
5. 添加 `/legal/terms`、`/legal/privacy`、`/legal/subscription`、`/legal/delete-account` 页面。
6. 配置 App Store Server Notifications V2 回调地址：

```text
https://123.gongxiang.cloud/api/billing/apple/webhook
```

## 当前开发状态

已生成：

- SwiftUI App 工程源码。
- XcodeGen 配置。
- 手机验证码登录流程。
- 会员购买和恢复购买调用。
- StoreKit 2 交易发送。
- APNs Token 注册接口。
- AI 生成/文字导入/自由训练入口。
- MariaDB 迁移。
- Node.js 短信、Apple 交易验证和手机端路由模块。

尚未完成或需要 Mac/Apple 账号：

- 在 Xcode 中编译。
- Apple Developer Team 配置。
- App Icon 和 Launch Screen。
- App Store Connect 商品创建。
- Apple 沙盒购买测试。
- 真实短信服务商配置。
- ICP/App 备案。
- App Review 材料。
- 真实 APNs 推送发送和定时任务。

## 注意

当前工程是可继续开发的源码骨架，不是已经完成 App Store 上架的成品。SwiftUI 代码必须在 Mac/Xcode 中编译、运行和通过 Apple 沙盒购买测试后，才能进入正式上架流程。
