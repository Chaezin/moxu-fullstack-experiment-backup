# 拾光 Flutter WebView 应用

拾光最新网页界面的跨平台应用外壳。iOS、Android 和 macOS 启动后加载应用内置的网页资源：

`assets/web/index.html`

内置版通过 `assets/web/src/demo-api.js` 提供 `/api/v1` 演示接口，包含测试登录、历史对话、成长卡片、能力线索、月报、推荐方向和聊天回复。演示数据保存在设备本地，不依赖腾讯云服务。

## 平台实现

- Android、iOS、macOS：Flutter 官方 `webview_flutter`，加载内置演示版
- Android、iOS、macOS：Flutter 官方 `webview_flutter`，加载内置演示版
- Windows：基于 Edge WebView2 的 `webview_flutter_windows`，加载同一套内置 `assets/web`
- 支持 JavaScript、站内返回、加载进度、失败提示和重新加载
- macOS 沙盒与 Android 已配置联网权限

## 语音输入

在对话输入区点击“说话”开始识别，再次点击“停止”后，识别文字会追加到已有输入并自动发送。首次使用需要允许麦克风和语音识别权限。应用不保存或上传原始录音。

语音输入面向 60 秒以内的短句。中英文混合识别由设备系统能力提供，不同系统和语言包的准确率可能不同。Windows 支持需在完成本机 Flutter C++ 构建环境后进行真机验收。

## 本地验证

```bash
../.tooling/flutter/bin/flutter analyze
../.tooling/flutter/bin/flutter test
```

## 运行

```bash
../.tooling/flutter/bin/flutter run -d macos
```

Android、iOS、Windows 分别选择对应设备运行。Windows 设备需要安装 Microsoft Edge WebView2 Runtime。

## 演示账户

- 手机号：`13800138000`
- 密码：`Shiguang2026!`
- 验证码：`202608`
- 也可使用“本设备一键登录”
