# 拾光 Flutter 队友开发包

## 直接登录体验

- 手机号：`13800138000`
- 密码：`Shiguang2026!`
- 验证码：`202608`
- 本地开发时也可以点击“本设备一键登录”。

当前安装包默认使用内置演示接口和设备本地数据，因此队友无需获得 API Key 或云数据库密码，也能登录并查看完整界面。

## 开始开发

1. 安装 Flutter、Xcode（iOS）或 Android Studio（Android）。
2. 在终端进入解压后的 `shiguang_flutter` 文件夹。
3. 运行：

```bash
flutter pub get
flutter doctor
flutter run
```

如果有多个设备，可以先运行 `flutter devices`，再运行：

```bash
flutter run -d 设备ID
```

## 项目入口

- Flutter 入口：`lib/main.dart`
- 当前 UI：`assets/web/index.html`
- 页面逻辑：`assets/web/src/app.js`
- 样式：`assets/web/src/*.css`
- 演示接口：`assets/web/src/demo-api.js`

## 语音输入

在对话输入区点击“说话”开始识别，再次点击“停止”后，识别文字会追加到已有输入并自动发送。首次使用需要允许麦克风和语音识别权限。应用不保存或上传原始录音。

语音输入面向 60 秒以内的短句。中英文混合识别由设备系统能力提供，不同系统和语言包的准确率可能不同。Windows 支持需在完成本机 Flutter C++ 构建环境后进行真机验收。

## 接入共同云端

开发包不包含 `.env`、API Key 和数据库密码。需要联调云端时，应由项目负责人单独发送一份 `.env.example` 字段说明；每位开发者在自己的电脑创建 `.env`，真实密钥不要通过微信、ZIP 或 GitHub 传递。

正式给外部测试者安装时，iPhone 建议使用 TestFlight；仅用于开发的队友可以直接用 Xcode/Flutter 运行源码。
