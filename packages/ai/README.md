# 我是谁 Agent 接入模块

本目录由《Agent 模型接入交付包 1.1》整理而来，用于后端组装模型上下文、校验结构化输出和执行行为回归测试。这里是受版本控制的实现输入，不包含模型密钥、用户档案或运行日志。

## 目录

- `rules/`：每次调用都加载的角色、安全、隐私和输出边界。
- `tasks/`：一次调用只加载一个任务定义。
- `knowledge/`：按任务路由、最小化加载的公共知识。
- `schemas/`：原始字段说明及可由程序执行的 JSON Schema。
- `tests/`：Agent 行为回归案例。
- `SOURCE-README.md`：交付包原始总说明。

## 后端任务映射

| API | taskType | 任务文件 | 输出 |
|---|---|---|---|
| `POST /api/chat/reply` | `chat_reply` | `tasks/chat-reply.md` | 自然语言流 |
| `POST /api/cards/generate` | `build_card` | `tasks/build-card.md` | `schemas/card.schema.json` |
| `POST /api/profile/proposals` | `propose_profile_updates` | `tasks/update-profile.md` | `schemas/profile-update.schema.json` |
| `POST /api/reports/generate` | `build_report` | `tasks/build-report.md` | `schemas/report.schema.json` |

## 调用顺序

1. 后端验证登录身份、数据权限、限流和固定安全分流。
2. 按 `task-map.json` 加载公共规则、唯一任务文件及最少知识片段。
3. 加入当前用户明确允许使用的档案、会话摘要和本轮输入。
4. 从后端调用模型；密钥绝不发送到 APP。
5. 对结构化任务执行 JSON Schema 校验，并核对所有来源 ID。
6. 将结果作为草稿返回。卡片、能力和报告必须经用户确认后才能保存。
7. 记录规则版本、任务、模型、耗时、用量和校验结果，不记录内部推理。

## 上线前仍需实现

- 模型提供方适配器与流式输出。
- 固定安全分流和已核验帮助资源。
- 身份鉴权、用户级数据隔离、撤回与删除。
- Schema 校验、来源 ID 校验、超时、重试和审计。
- 将 `tests/agent-behavior-cases.md` 转换为自动化回归测试。

