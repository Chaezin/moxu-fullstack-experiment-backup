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
- Web 语音输入测试：10 项通过。
- Python 后端语法编译检查：通过。
- Git 空白与冲突标记检查：通过。
- 未带入 `.env.local`、数据库、依赖目录或构建缓存。

## 尚未完成的验证

- 当前机器未安装 Flutter SDK，未运行 `flutter analyze`、Flutter 测试及真实设备构建。
- 当前 Python 环境缺少 `pytest` 及后端依赖，未运行 FastAPI 全量测试。

## 合入 main 前必须处理

交接文档称安装包默认使用内置演示接口，但当前运行配置只在 URL 带 `?demo=1` 时开启演示模式：

- `assets/web/src/runtime-config.js` 默认指向 `http://127.0.0.1:8000`。
- Android、iOS、macOS 加载 `assets/web/index.html`，没有附加 `demo=1`。
- Windows 加载 `https://appassets.shiguang/index.html`，同样没有附加 `demo=1`。

因此未运行本机 Python 后端时，安装包的登录和数据接口可能不可用。修复并完成 Flutter、Python 测试前，本分支仅用于保存与评审，不应合入 `main`。

另外，Python 启动入口允许使用固定开发密钥。部署到公开环境前，必须强制配置 `SHIGUANG_SECRET_KEY`，不能沿用默认值。
