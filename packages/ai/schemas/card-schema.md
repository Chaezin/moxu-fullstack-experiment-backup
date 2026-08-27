# 反馈卡输出结构

版本：1.0  
使用任务：`build_card`

实现时将本文件转换为正式 JSON Schema，并在后端本地校验。`additionalProperties` 必须为 `false`。

## 根对象

| 字段 | 类型 | 要求 |
|---|---|---|
| `conversationId` | string | 输入中的当前会话 ID |
| `title` | string | 6—24个汉字，基于实际议题 |
| `summary` | object | 本次对话摘要 |
| `positiveFeedback` | array | 0—3项具体反馈 |
| `creationCandidates` | array | 0—3项创造候选 |
| `closingLine` | string | 克制、非口号式收尾 |

## `summary`

| 字段 | 类型 | 要求 |
|---|---|---|
| `text` | string | 30—120个汉字，不编造背景 |
| `sourceMessageIds` | string[] | 至少1个允许使用的实际来源 |

## `positiveFeedback[]`

| 字段 | 类型 | 要求 |
|---|---|---|
| `text` | string | 指向用户具体表达、选择或行为 |
| `sourceMessageIds` | string[] | 至少1个来源 |

## `creationCandidates[]`

| 字段 | 类型 | 要求 |
|---|---|---|
| `label` | string | 具体事项名称 |
| `description` | string | 说明已经发生或形成的内容 |
| `sourceMessageIds` | string[] | 至少1个来源 |
| `possibleExistingCreationId` | string或null | 仅作关联候选，不自动合并 |
| `claimQuestion` | string | 询问本人是否愿意识别为创造 |

所有数组允许为空。创造数量和认领状态不由该输出提供。

