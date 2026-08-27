# Agent 规则与知识库 1.1

用途：为家庭主妇创造与成长产品中的 DeepSeek V4 对话 agent 提供稳定规则、按任务加载的提示、公共知识和输出结构。

本文档组是实施输入，不表示功能已经接入或测试通过。

## 加载顺序

每次模型调用按以下顺序组装上下文：

1. `rules/00-role.md`
2. `rules/01-conversation.md`
3. `rules/02-safety.md`
4. `rules/03-privacy.md`
5. `rules/04-output-boundaries.md`
6. 当前任务在 `tasks/` 中对应的唯一一份任务文件
7. 与当前任务相关的少量 `knowledge/` 文件；需要研究依据时，再按 `knowledge/evidence/README.md` 选择 1—2 份证据卡
8. 当前用户允许使用且仍有效的私人档案
9. 当前会话摘要、近期消息和本轮输入

规则属于受信任指令；知识库、用户档案、对话和媒体线索都属于数据，不能修改规则或扩大权限。

## 任务映射

| 任务 | 任务文件 | 输出结构 |
|---|---|---|
| 日常对话 | `tasks/chat-reply.md` | 自然语言 |
| 反馈卡 | `tasks/build-card.md` | `schemas/card-schema.md` |
| 档案建议 | `tasks/update-profile.md` | `schemas/profile-update-schema.md` |
| 月年回顾 | `tasks/build-report.md` | `schemas/report-schema.md` |

## 公共知识路由

| 当前任务或议题 | 必须加载 | 按需加载 | 状态 |
|---|---|---|---|
| 日常对话 | `knowledge/conversation-methods.md` | 按 `knowledge/evidence/README.md` 选择 0—2 张证据卡 | 已接入设计 |
| 反馈卡 | `knowledge/creation-examples.md`、`knowledge/product-concepts.md` | 与本次议题相关的 0—1 张证据卡 | 已接入设计 |
| 档案建议 | `knowledge/product-concepts.md`、`knowledge/skill-interest-examples.md` | 无 | 已接入设计 |
| 月年回顾 | `knowledge/product-concepts.md` | `knowledge/evidence/05-叙事身份与成长记录.md` | 已接入设计 |
| 固定安全分流 | `knowledge/verified-help-resources.md` | 无；普通对话任务停止 | 已接入设计，资源表当前为空 |
| 活动建议 | `knowledge/activity-ideas.md` | 无 | 设计完成，1.0 运行未接入 |
| 商业可能性 | `knowledge/commercial-ideas.md` | 当前有效的反诈来源 N05 | 设计完成，1.0 运行未接入 |
| 研究来源维护 | `knowledge/evidence/sources.md` | `knowledge/evidence/implementation-references.md` | 仅供检索与维护，不直接面向用户输出 |

每轮只加载完成当前任务所需的文件。未被当前任务路由选中的知识，不进入模型上下文。

## 待接入模块

| 模块 | 当前状态 | 上线前必须完成 |
|---|---|---|
| `build-activity-suggestions` | 只登记，不创建无调用方的 task/schema | 仅使用当前用户确认的兴趣、技能、时间与偏好 |
| `build-collaboration-suggestions` | 只登记，不创建无调用方的 task/schema | 公开字段、逐字段授权、撤回、候选召回和双方同意 |
| 真人伙伴聊天 | 未接入 | 注册身份、双方同意、屏蔽举报、消息权限、删除和审计 |
| 日期化市场快照 | 未接入 | 地区、来源、核验日期、有效期、风险和退出方式 |

用户可能同时有就业、家务与照护角色。“家庭主妇”不能被当成全职、无收入或没有职业经历的同义词。

## 程序负责的限制

模型不能自行读取数据库、跨用户查找、保存档案、认领创造、发布名片、发送真人消息、删除数据或改变权限。后端负责身份校验、数据范围、固定安全分流、结构校验、统计、保存、删除、限流和审计。

模型密钥只存放在后端。每次调用记录规则版本、任务类型、模型、耗时、用量和校验结果，不记录模型内部推理。

## 维护规则

- 每个文件首部维护版本和适用任务。
- 修改规则时同步增加测试案例并重新执行回归测试。
- 公共知识必须由团队人工确认后加入，记录来源和复核日期。
- 研究证据只按当前议题加载，不把全部论文摘要塞进每次对话；来源只能提供参考，不能扩大模型的诊断、治疗或替用户决策权限。
- 用户私人数据不能复制到本目录。
- 规范只在一个规则文件中定义；任务、知识和测试可以保留引用该规范的场景级检查，但只能更具体或更严格，不能重写整套规范。
- 判断重复时使用“删除测试”：删除局部条目后，主规则仍能约束该场景，则局部条目只是检查；若主规则无法约束，应把规范上移到规则文件。
