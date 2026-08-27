# 拾光 Flutter 应用

拾光的原生跨平台版本，目标平台为 Android、iOS、macOS 与 Windows。

## 已完成

- Flutter 四端工程骨架
- 原生登录与注册界面
- 手机底部导航与桌面侧栏自适应布局
- 我的故事、我的记录、我的画像、我的同路人
- 成长卡片、月度总结、能力词库、个人记忆、隐私、导出、伙伴空间
- 摄像头权限说明弹窗
- 390 × 844 手机尺寸原生渲染测试图
- 静态分析与 Widget/Golden 测试

## 测试账号

- 账号：`13800138000`
- 密码：`Shiguang2026!`

## 本地验证

```bash
../.tooling/flutter/bin/flutter analyze
../.tooling/flutter/bin/flutter test
```

## 构建平台

```bash
flutter build apk
flutter build ipa
flutter build macos
flutter build windows
```

macOS/iOS 构建需要完整 Xcode；Android 构建需要 Android SDK；Windows 安装包应在 Windows 设备上构建。
