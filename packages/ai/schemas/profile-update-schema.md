# 个人档案更新输出结构

版本：1.0  
使用任务：`propose_profile_updates`

实现时转换为正式 JSON Schema，并在后端本地校验。`additionalProperties` 必须为 `false`。

## 根对象

| 字段 | 类型 | 要求 |
|---|---|---|
| `proposals` | array | 0—6项候选更新 |

## `proposals[]`

| 字段 | 类型 | 要求 |
|---|---|---|
| `type` | enum | `skill`、`interest`、`trying`、`collaboration_preference`、`conversation_preference` |
| `label` | string | 简短、具体、无诊断或人格判断 |
| `description` | string | 说明候选含义，不夸大熟练程度 |
| `evidenceLevel` | enum | `explicit`、`demonstrated`、`tentative` |
| `sourceIds` | string[] | 至少1个允许使用的实际来源 |
| `relation` | enum | `new`、`update_existing`、`add_source` |
| `existingEntryId` | string或null | 后两种关系必须填写 |
| `confirmationQuestion` | string | 供用户确认、修改或拒绝 |

不输出发布状态、记忆授权和用户确认结果；这些由用户操作及后端记录。

