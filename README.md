# 薄肌俱乐部

当前正式开发客户端已切换为 Flutter，用于快速预览并同时支持 iOS/Android。

- Flutter 客户端：`flutter/`
- 后端接入模块：`boji-ios/Backend/`
- 旧 SwiftUI 原型：`boji-ios/Boji/`，仅作参考。
- Windows 可运行 Web、Windows 和 Android 预览。
- iOS 最终构建、TestFlight、Apple 购买和 APNs 仍需 Mac 或云端 Mac。

进入 Flutter 工程：

```powershell
cd flutter
flutter create --platforms=web,android,ios .
flutter pub get
flutter run -d chrome
```

详细说明见 `flutter/README.md`。
