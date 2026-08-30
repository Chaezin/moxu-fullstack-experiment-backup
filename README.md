# 我是谁

> 一款以私人对话为入口的个人成长记录 App。Mochi 帮助用户整理具体经历，用户拥有最终解释权，并决定什么值得保存为成长卡片。

## 演示视频

[![观看“我是谁”App 演示](docs/media/who-am-i-demo-cover.png)](docs/media/who-am-i-demo.mp4)

点击封面观看 32 秒产品演示。

## 为什么做

很多人经历了大量具体的行动、选择和变化，却很难把它们整理成属于自己的表达。普通聊天机器人往往急于建议、总结或贴标签，也容易让模型生成的判断取代用户本人。

“我是谁”希望提供一个可以安心讲述、回看和修正的私人空间。AI 助手 Mochi 负责倾听与整理；产品规则要求 AI 产出的内容只是候选草稿，最终解释权和保存权属于用户。

## 核心体验

```text
讲述一段真实经历
→ Mochi 倾听并帮助梳理
→ AI 生成可修改的成长卡片草稿
→ 用户确认、改写或拒绝
→ 本人认可的内容进入记录、能力线索与阶段回顾
```

当前产品包含四个一级入口：

- **我的故事**：与 Mochi 对话，支持历史对话、语音输入和不同交流模式。
- **我的记录**：查看成长卡片、成长月历和月度回顾。
- **我的画像**：从已确认的经历中查看能力线索、证据来源和待验证边界。
- **我的同路人**：只基于双方主动公开的信息探索方向、认识同路人。

产品不提供心理诊断，也不以效率、收入、持续产出或积极情绪衡量用户价值。

## 当前完成内容

| 部分 | 当前状态 |
| --- | --- |
| Flutter 跨平台 App | 已内置完整演示数据，可在 Android、iOS、macOS 和 Windows 外壳中运行 |
| 移动端与桌面端 UI | 已覆盖登录、首次引导、对话、记录、画像、同路人和设置 |
| 云朵助手 Mochi | 已接入角色规则、安全预检和 DeepSeek 流式聊天原型 |
| 成长闭环 | 已实现对话、卡片生成与修改、能力证据、反馈修正、月报和定时整理相关接口 |
| 账户与数据 | Node 原型支持手机号账户；FastAPI 后端支持认证、资料、会话和用户隔离 |
| 社交探索 | 已实现公开名片、方向推荐、同路人消息、分享与隐私控制相关接口 |
| AI 契约 | 已提供角色规则、任务拆分、JSON Schema 和 OpenAPI 技术契约 |

## 最快体验：Flutter 演示版

Flutter App 内置网页资源和本地演示接口，不需要云服务或 DeepSeek Key 即可体验完整界面。

```powershell
cd shiguang_flutter
flutter pub get
flutter devices
flutter run -d <device-id>
```

演示账户：

- 手机号：`13800138000`
- 密码：`Shiguang2026!`
- 验证码：`202608`
- 也可以选择“本设备一键登录”

演示数据保存在当前设备本地，不会写入正式云端数据库。

## 运行 Node 网页与聊天原型

该服务提供 `新版网页/`，并包含手机号账户、页面验证码和 DeepSeek 流式聊天接口。

```powershell
npm install
Copy-Item .env.example .env
# 编辑 .env，填写服务端 DEEPSEEK_API_KEY
npm run dev
```

浏览器访问：`http://127.0.0.1:4173`

本地账户数据写入被 Git 忽略的 `.data/users.json`。验证码只显示在页面中，不发送真实短信；模型密钥仅保存在服务端。

## 运行 FastAPI v1 后端

FastAPI 服务覆盖账户、资料、对话、卡片、技能、报告、同路人、导出、照片和分享等核心接口。

```powershell
cd shiguang_flutter\backend
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
$env:SHIGUANG_SECRET_KEY = "dev-only-change-me-at-least-32-characters"
.venv\Scripts\python.exe -m uvicorn run:app --host 127.0.0.1 --port 8000 --reload
```

健康检查：`http://127.0.0.1:8000/api/v1/health`

默认数据层为本地 SQLite；生产部署可通过 `SHIGUANG_DATABASE_URL` 切换至 PostgreSQL。

## 测试

```powershell
# Node 服务与 Agent 规则
npm test

# 内置 Web 演示契约
cd shiguang_flutter\assets\web
node --test test/*.test.mjs

# Flutter
cd ..\..
flutter analyze
flutter test

# FastAPI
cd backend
.venv\Scripts\python.exe -m pytest -q
```

## 隐私与安全边界

- 私人内容默认不公开；公开名片只包含用户主动选择的信息。
- 产品规则要求 AI 只提出卡片、能力和画像候选，不能替用户确认身份或价值。
- 用户可以查看来源、修改、拒绝、删除或撤回已保存内容。
- 语音输入由用户主动开启，App 不保存或上传原始录音。
- 密码使用强哈希保存；API Key、令牌和数据库凭据不得进入前端或模型上下文。
- 真人私聊默认不发送给 AI，也不进入成长卡片。
- 项目不提供心理诊断、医疗建议、法律结论或金融决策。

## 项目结构

```text
.
├── 新版网页/                   # Node 服务提供的当前网页 UI
├── apps/api/                  # Node 账户、聊天、安全预检与本地数据层
├── shiguang_flutter/          # Flutter 跨平台 App 与内置离线演示
│   ├── assets/web/            # App 内置网页、Mochi 云朵素材和演示 API
│   └── backend/               # FastAPI v1 服务、SQLite/PostgreSQL 数据层与测试
├── packages/ai/               # AI 角色规则、任务、知识与 JSON Schema
├── packages/contracts/        # OpenAPI 接口契约
├── deploy/tencent-cloud/      # 腾讯云部署用网页镜像
├── docs/PRD.md                # 产品需求与隐私、安全边界
└── tests/                     # Node 契约和 Agent 行为测试
```

## 当前边界

当前仓库适合比赛演示、产品验证和本地联调。FastAPI 分析任务目前会直接创建 `active` 成长卡片，再由用户修改、删除或撤销；正式版本仍需增加“保存前确认”状态，才能完整落实用户确认优先的产品规则。

正式上线前还需完成云端数据库与对象存储迁移、正式短信或 OAuth、生产任务调度、权限压测以及完整端到端验收。

## 进一步阅读

- [产品需求文档](docs/PRD.md)
- [Flutter App 说明](shiguang_flutter/README.md)
- [FastAPI 后端说明](shiguang_flutter/backend/README.md)
- [AI 规则与任务结构](packages/ai/README.md)
- [OpenAPI 契约](packages/contracts/openapi.yaml)
