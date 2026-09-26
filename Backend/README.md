# 后端接入说明

本目录包含 iOS 手机登录、Apple 订阅验证和推送 Token 所需的模块。

## 文件

- `migrations/20260926_ios_mobile.sql`：数据库迁移。
- `lib/sms.mjs`：验证码生成、校验和阿里云短信发送。
- `lib/apple.mjs`：Apple JWS 解码、App Store Server API 查询和交易校验。
- `routes/mobile.mjs`：手机号登录、用户信息、建档、推送 Token、Apple 会员接口。

## 重要接口

```text
POST /api/auth/sms/send
POST /api/auth/sms/verify
GET  /api/me
POST /api/onboarding
POST /api/auth/logout
POST /api/push-token
POST /api/billing/apple/verify
POST /api/billing/apple/webhook
```

## 注册方式

在 `server.mjs` 中：

```js
import { registerMobileRoutes } from "./routes/mobile.mjs";

registerMobileRoutes(on);
```

放在已有路由注册之后。

## 生产安全要求

- `SMS_PEPPER` 必须是长随机值。
- Apple `.p8` 私钥只能保存在服务器安全目录。
- 不要打印验证码、短信内容、Apple 私钥或完整交易原文。
- 生产环境禁止 `SMS_PROVIDER=mock`。
- 生产环境建议使用 `APPLE_VERIFICATION_MODE=server`。
- 支付回调必须幂等。
- 所有会员权益以服务端交易验证结果为准，不信任客户端直接上报的会员状态。
