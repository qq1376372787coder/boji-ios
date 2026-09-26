# Mac / Apple / 后端接入步骤

## 1. Apple Developer

1. 使用 Apple ID 登录 Apple Developer Program。
2. 注册个人开发者账号。
3. 创建 App ID：`cloud.gongxiang.boji`。
4. 创建 iOS Distribution Certificate。
5. 创建 Provisioning Profile。
6. 在 App Store Connect 创建 App。
7. 创建自动续费订阅商品。

建议商品配置：

- 商品名称：薄肌俱乐部年度会员。
- 产品 ID：`cloud.gongxiang.boji.annual12`。
- 价格档位：中国大陆 6 元。
- 订阅周期：12 个月。
- 不设置免费试用。
- 订阅组：Boji Membership。

如果产品 ID 或 Bundle ID 修改，需要同步修改：

- `project.yml`
- `Boji/Config.swift`
- `Backend/lib/apple.mjs` 使用的 `APPLE_PRODUCT_ID`
- `Backend/routes/mobile.mjs`
- App Store Connect 商品 ID

## 2. Xcode

```bash
brew install xcodegen
cd boji-ios
xcodegen generate
open Boji.xcodeproj
```

在 Signing & Capabilities 中选择个人 Team。

## 3. Apple 交易验证

创建 App Store Connect API Key：

1. Users and Access。
2. Integrations。
3. App Store Connect API。
4. 生成 In-App Purchase key。
5. 下载 `.p8`。
6. 记录 Key ID 和 Issuer ID。
7. 将 `.p8` 放在服务器安全目录，例如：

```text
/var/www/shuaqima-123/secrets/apple_api_key.p8
```

服务器环境变量：

```env
APPLE_ENVIRONMENT=production
APPLE_VERIFICATION_MODE=server
APPLE_BUNDLE_ID=cloud.gongxiang.boji
APPLE_PRODUCT_ID=cloud.gongxiang.boji.annual12
APPLE_ISSUER_ID=...
APPLE_KEY_ID=...
APPLE_PRIVATE_KEY_PATH=/var/www/shuaqima-123/secrets/apple_api_key.p8
```

开发期可以使用：

```env
APPLE_ENVIRONMENT=sandbox
APPLE_VERIFICATION_MODE=mock
```

## 4. App Store Server Notifications

在 App Store Connect 中配置：

```text
https://123.gongxiang.cloud/api/billing/apple/webhook
```

生产环境建议启用 Apple Server API 校验，不要只解析客户端传来的交易 JSON。

## 5. 手机短信

开发期：

```env
SMS_PROVIDER=mock
NODE_ENV=development
SMS_PEPPER=replace-with-long-random-secret
```

生产环境接入阿里云短信或同类服务：

```env
SMS_PROVIDER=aliyun
SMS_ACCESS_KEY_ID=...
SMS_ACCESS_KEY_SECRET=...
SMS_SIGN_NAME=...
SMS_TEMPLATE_CODE=...
```

短信模板必须包含验证码参数，并在服务商后台审核通过。

## 6. 隐私和审核材料

准备：

- 用户协议。
- 隐私政策。
- 订阅条款。
- 退款规则。
- 账号注销页面。
- 数据删除说明。
- AI 免责声明。
- 未成年人说明。
- 相机和照片权限说明。
- App Privacy 数据声明。
- 年龄分级。
- 测试手机号和验证码。
- Apple 沙盒测试账号。

## 7. 上架前检查

- iOS 17 真机登录。
- 验证码登录。
- 建档。
- AI 生成计划。
- 文字导入。
- 自由训练。
- Apple 购买。
- 恢复购买。
- 会员到期。
- 通知授权。
- 账号注销。
- 隐私政策链接。
- 网络错误提示。
- Apple 沙盒订阅续费。
- App Store Server Notifications。

## DeepSeek 4.1 Flash

生产 `.env`：

```env
DEEPSEEK_API_KEY=...
DEEPSEEK_MODEL=deepseek-v4.1-flash
```

客户端接口：

```text
POST /api/ai/summary
```

未配置 Key 时接口返回示例日报，不会调用外部 AI。
