# 月度与年度回顾输出结构

版本：1.0  
使用任务：`build_report`

实现时转换为正式 JSON Schema，并在后端本地校验。`additionalProperties` 必须为 `false`。

## 根对象

| 字段 | 类型 | 要求 |
|---|---|---|
| `reportType` | enum | `monthly`或`yearly`，原样采用输入 |
| `periodStart` | string | 原样采用后端提供的时间 |
| `periodEnd` | string | 原样采用后端提供的时间 |
| `claimedCreationCount` | integer | 原样采用后端统计，可为0 |
| `opening` | string | 20—80个汉字，避免夸张判断 |
| `creationHighlights` | array | 有效创造摘要，可为空 |
| `confirmedDiscoveries` | array | 本人已确认技能兴趣，可为空 |
| `themeChanges` | array | 有实际来源支持的主题变化，可为空 |
| `closing` | string | 不施压、不作心理结论的收尾 |

## 三类内容数组

每项统一包含：

| 字段 | 类型 | 要求 |
|---|---|---|
| `title` | string | 简短标题 |
| `text` | string | 只描述期间内有证据的内容 |
| `sourceIds` | string[] | 至少1个仍有效来源 |

报告不得输出排名、得分、诊断、收入保证或与他人比较。

