# 我是谁 Flutter 应用

“我是谁”的原生 Flutter 移动版。正式入口使用毛毡视觉页面；Ivy 原有的 WebView 页面和演示接口继续保留为功能迁移参考，不再作为 App 启动入口。

## 原生移动端

- 原生登录与注册界面
- 可收缩左侧导航
- 我的故事、记录、画像与同路人
- 成长卡片、月度总结、能力词库、个人记忆、隐私与导出
- 真实毛毡材质资产、正方形矢量图标与多宽度布局测试

## 保留的 Web 演示资源

`assets/web/index.html`

内置版通过 `assets/web/src/demo-api.js` 提供 `/api/v1` 演示接口，包含测试登录、历史对话、成长卡片、能力线索、月报、推荐方向和聊天回复。演示数据保存在设备本地，不依赖腾讯云服务。

这些资源用于把既有功能逐项迁移到原生 Flutter，不会由 `lib/main.dart` 直接加载。

## 旧 WebView 平台文件

- `lib/standard_webview_page.dart`
- `lib/windows_webview_page.dart`

它们暂时保留用于对照，不属于当前原生移动端入口。

## 本地验证

```bash
D:/flutter/bin/flutter analyze --no-pub
D:/flutter/bin/flutter test --concurrency=1 --no-pub
```

## 运行

```bash
D:/flutter/bin/flutter run
```

Android、iOS 分别选择对应设备运行。iOS 最终构建仍需要 macOS 与 Xcode。

## 原生应用连接后端

原生入口直接调用仓库内 `apps/api/server.mjs` 的 `/api/v1` 接口，已接入账号登录、注册验证码、对话读取、消息发送和记录刷新。

先在仓库根目录启动服务端：

```bash
npm start
```

默认开发地址：

- Android 模拟器：`http://10.0.2.2:4173`
- iOS 模拟器、Windows 和 macOS：`http://127.0.0.1:4173`

真机或部署环境通过构建参数指定地址：

```bash
flutter run --dart-define=API_BASE_URL=https://你的服务端地址
```

发送 AI 回复还要求服务端配置 `DEEPSEEK_API_KEY`。Flutter 端不会保存或接触该密钥。

## 演示账户

- 手机号：`13800138000`
- 密码：`Shiguang2026!`
- 验证码：`202608`
