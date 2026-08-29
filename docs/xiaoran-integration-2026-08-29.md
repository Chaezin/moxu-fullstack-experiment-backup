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
- Python 后端语法编译检查：通过。
- 缺失或过短密钥拒绝启动检查：通过。
- Git 空白与冲突标记检查：通过。
- 未带入 `.env.local`、数据库、依赖目录或构建缓存。

## 尚未完成的验证

- 当前机器未安装 Flutter SDK，未运行 `flutter analyze`、Flutter 测试及真实设备构建。

## 已处理的阻断项

原交接文档称安装包默认使用内置演示接口，但原运行配置只在 URL 带 `?demo=1` 时开启演示模式：

- `assets/web/src/runtime-config.js` 默认指向 `http://127.0.0.1:8000`。
- Android、iOS、macOS 加载 `assets/web/index.html`，没有附加 `demo=1`。
- Windows 加载 `https://appassets.shiguang/index.html`，同样没有附加 `demo=1`。

运行配置现已识别 `file:` 与 Windows 内置域名，在安装包中默认启用离线演示接口；普通浏览器预览仍默认连接真实后端，也可用 `?demo=1` 显式进入演示模式。

Python 应用工厂与启动入口现已移除固定开发密钥，缺失或少于 32 位的 `SHIGUANG_SECRET_KEY` 会阻止服务启动。
