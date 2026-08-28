# 拾光 Flutter WebView 应用

拾光网页的跨平台应用外壳，启动后加载腾讯云正式页面：

`https://a-d7g81pr41f2b54449-1475901646.tcloudbaseapp.com/demo/`

## 平台实现

- Android、iOS、macOS：Flutter 官方 `webview_flutter`
- Windows：基于 Edge WebView2 的 `webview_flutter_windows`
- 支持 JavaScript、站内返回、加载进度、失败提示和重新加载
- macOS 沙盒与 Android 已配置联网权限

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
