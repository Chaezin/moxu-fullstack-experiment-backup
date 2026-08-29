# 晓冉代码集成记录

## 来源与边界

- 来源仓库：`zxr-123/xinshiguang`
- 来源分支：`main`
- 来源提交：`264c5d9468a8adbf4b2762e450cc1f4f0ca8f58b`
- 集成目标：本仓库 `shiguang_flutter/`
- Ivy 原仓库未修改；本仓库根目录现有 Node 服务保持不变。

晓冉仓库是从 Ivy 仓库的 `shiguang_flutter/` 子项目继续开发而来，因此本次采用子目录覆盖映射，不把 Flutter 文件散落到仓库根目录。晓冉新增的 FastAPI 后端保留在 `shiguang_flutter/backend/`。目前仓库同时存在根目录 Node 后端与该 Python 后端，后续应由团队确认最终使用哪套接口。

## 已完成检查

- 根目录 Node 测试：5 项通过。
- Web 与语音输入测试：24 项通过。
- FastAPI 后端测试：48 项通过。
- Flutter 3.47.2 静态分析：通过，未发现问题。
- Flutter 测试：29 项通过。
- Android 调试 APK 构建：通过。
- Python 后端语法编译检查：通过。
- 缺失或过短密钥拒绝启动检查：通过。
- Git 空白与冲突标记检查：通过。
- 未带入 `.env.local`、数据库、依赖目录或构建缓存。

## 尚未完成的验证

- 尚未在 Android 真机上安装并完成功能验收。
- 本机没有 Visual Studio C++ 构建组件，尚未构建 Windows 桌面版。

Flutter 验证使用集成提交 `051c9957afdc0e64f1421ce40b01343efdf33982` 的英文路径副本完成。原工作目录包含中文时，Dart 分析服务会在初始化阶段解析失败；该问题发生在代码分析开始前。

Android 构建当前存在两项非阻断警告：`speech_to_text` 插件未来需要迁移到 Built-in Kotlin，现有 Android 命令行工具只能识别较旧的 SDK XML 格式。本次调试 APK 仍成功生成。

## 已处理的阻断项

原交接文档称安装包默认使用内置演示接口，但原运行配置只在 URL 带 `?demo=1` 时开启演示模式：

- `assets/web/src/runtime-config.js` 默认指向 `http://127.0.0.1:8000`。
- Android、iOS、macOS 加载 `assets/web/index.html`，没有附加 `demo=1`。
- Windows 加载 `https://appassets.shiguang/index.html`，同样没有附加 `demo=1`。

运行配置现已识别 `file:` 与 Windows 内置域名，在安装包中默认启用离线演示接口；普通浏览器预览仍默认连接真实后端，也可用 `?demo=1` 显式进入演示模式。

Python 应用工厂与启动入口现已移除固定开发密钥，缺失或少于 32 位的 `SHIGUANG_SECRET_KEY` 会阻止服务启动。
