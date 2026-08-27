# 模序网页端协作分工 Review（整理版）

日期：2026-08-26  
仓库：[Ldmsy/moxu-fullstack-experiment](https://github.com/Ldmsy/moxu-fullstack-experiment)  
用途：供 Ivy 的 agent 独立核验仓库现状、协作分工与后续开发路径。

> 本文仅用于评审和协作规划，不授权合并 PR、创建远程分支、修改仓库或变更产品范围。

## 一、评审目标

项目最终需要交付：

- 可访问的桌面及移动端响应式网站；
- 可安装的手机 App；
- Web 与 App 共用账号、业务 API、数据库及持久数据。

Ivy 当前实现的是手机尺寸网页，并非原生或可安装 App。双方计划共同维护同一套响应式 Web：Ivy 负责移动端和核心前端逻辑，用户负责桌面端布局。

本次请 Ivy 的 agent 独立判断：

1. 当前仓库与 PR #5 的事实描述是否准确；
2. 已提出的分工能否安全落地；
3. PR #5 应如何处理；
4. 桌面开发前需要完成哪些结构调整；
5. 是否存在冲突更低、回退更容易的协作方案。

## 二、已核验的项目现状

### 2.1 交付范围

本地执行方案：

`D:\202608北京黑客松\软件\软件与App开发执行方案-2.1.md`

方案明确要求：

- 网站与手机 App 均需交付；
- 网站优先提供可访问版本，手机 App 同步开发；
- 手机浏览器访问网站不能替代 App 安装与使用验收；
- 网站和 App 分别实现界面，共用业务 API、账号、数据库、AI 服务和真人消息服务；
- 用户可在网站和 App 分别注册、登录，并通过同一账号读取一致数据。

因此，手机网页只能覆盖网站的窄屏体验，不能直接视为可安装 App。

### 2.2 仓库结构

已通过公开 GitHub API 和 `gh` CLI 进行只读核验：

| 项目 | 当前情况 |
|---|---|
| 仓库 | `Ldmsy/moxu-fullstack-experiment` |
| 可见性 | Public |
| 默认分支 | `main` |
| 主要语言 | JavaScript、HTML、CSS |
| 服务端 | Node.js 22 原生 HTTP Server |
| License | 未设置 |
| 在线演示 | 未配置 |
| 手机 App 工程 | 未发现 `apps/mobile` 或其他可安装 App 工程 |

`main` 主要结构：

```text
apps/
  api/server.mjs
  web/index.html
  web/app.js
  web/styles.css
packages/
  contracts/openapi.yaml
tests/
  contract.test.mjs
.github/
  workflows/check.yml
```

README 已约定四条协作线：

- `feat/frontend-ux`
- `feat/backend-api`
- `feat/ai-contract`
- `experiment/hardware-test`

参考：[README](https://github.com/Ldmsy/moxu-fullstack-experiment/blob/main/README.md)

### 2.3 后端与接口契约

当前 OpenAPI 仅包含：

```text
POST /api/comfort
request: event
response: reply, actions, contractVersion
```

参考：[openapi.yaml](https://github.com/Ldmsy/moxu-fullstack-experiment/blob/main/packages/contracts/openapi.yaml)

尚未实现完整产品所需的：

- 真实注册、登录和用户数据隔离；
- 对话会话与保存模式；
- 反馈卡、私人档案及个人名片；
- 联系请求与真人消息；
- 月度、年度回顾；
- 删除、撤回和权限管理；
- Web 与 App 跨端同步。

### 2.4 PR #5 概况

[PR #5：feat(web): add Shiguang mobile experience](https://github.com/Ldmsy/moxu-fullstack-experiment/pull/5)

| 项目 | 情况 |
|---|---|
| 来源分支 | `codex/app-ui-v1` |
| 目标分支 | `main` |
| CI | 通过 |
| 变更规模 | 16 个文件，约 275 行新增、24 行删除 |

PR 新增了完成度较高的手机尺寸网页原型，包括登录视觉、底部导航、AI 对话、历史对话、报告与月历、个人空间、隐私面板、语音按钮、摄像头授权弹窗、反馈卡、能力与档案页面。

但代码仍位于 `apps/web/`，主容器为 `<main class="phone-shell">`，因此其性质是手机外观网页，而不是可安装 App。

参考：

- [apps/web/src/app.js](https://github.com/Ldmsy/moxu-fullstack-experiment/blob/codex/app-ui-v1/apps/web/src/app.js)
- [apps/web/index.html](https://github.com/Ldmsy/moxu-fullstack-experiment/blob/codex/app-ui-v1/apps/web/index.html)

### 2.5 PR #5 的功能边界

已核验到：

1. 原网页中的 `fetch('/api/comfort')` 已被移除，新 `app.js` 未调用该接口；
2. 登录仅将 `shiguang-session=active` 写入 `localStorage`；
3. 对话、卡片和档案均使用 `localStorage`；
4. 语音与摄像头按钮只切换前端状态；
5. AI 回复及大量报告数据为固定演示内容；
6. 页面包含“7 次认领”“86% 观察力”“23 条记忆”等固定统计；
7. CI 仅验证 `comfort()` 返回字符串和数组，未验证网页运行、API 接入、认证、保存、响应式或 App 构建。

### 2.6 CSS 现状

PR #5 连续加载 8 份 CSS：

```text
styles.css
blue-print.css
tech-glass.css
product-cleanup.css
clean-reset.css
ocean-flow.css
clarity-pass.css
workflow.css
```

CSS 合计约 68 KB，另有约 28 KB 的单文件 `app.js`。多层覆盖可能增加并行修改时的冲突、回归排查成本和视觉漂移。

## 三、已确认的共同决定

### 3.1 视觉方向

主配色已确定为：**方案三｜茶杏橄榄**。

视觉终审文件：

`D:\202608北京黑客松\软件\视觉\跨年龄女性温馨慰藉视觉执行报告.md`

色卡文件：

`D:\202608北京黑客松\软件\视觉\色卡\03-茶杏橄榄.png`

```css
:root {
  --color-bg: #F6F1E7;
  --color-surface: #FFFCF6;
  --color-text: #312C25;
  --color-text-muted: #635B50;
  --color-primary: #566044;
  --color-attention: #9B5D3F;
  --color-privacy: #586977;
  --color-soft: #E8EBDD;
}
```

执行原则：

- 暖而不甜，亲密但有边界；
- 真实生活，缓慢可呼吸，清楚可掌控；
- 正文不小于 17px；
- 触控目标不小于 44×44px；
- 明确区分 AI 草稿、临时预览、本人确认、暂停展示、已撤销五种状态；
- 保存选择、媒体授权、档案记忆三个开关互不替代；
- “0 就是 0”，不得以固定积极统计冒充用户真实结果。

### 3.2 响应式 Web 分工

双方维护同一套内容、状态和 API，不分别开发两套互不相关的网页。

| 文件或范围 | 负责人 |
|---|---|
| `app.js` | Ivy |
| `base.css` | Ivy |
| `mobile.css` | Ivy |
| `desktop.css` | 用户 |
| `tokens.css` | 双方共同确认 |
| API 字段和业务状态 | 不得由任一视觉人员单独修改 |

视口责任：

```text
390px          Ivy 负责
768px          双方共同检查
1024–1440px    用户负责
```

建议断点：

```css
@media (max-width: 767px) {}
@media (min-width: 768px) and (max-width: 1023px) {}
@media (min-width: 1024px) {}
```

## 四、待独立核验的建议方案

> 以下为 Codex 建议，并非已执行决定。请 Ivy 的 agent 独立判断，不必默认同意。

### 4.1 暂不将 PR #5 直接合入 `main`

主要理由：

- 移除了原有真实 API 调用；
- 登录和保存仍是本地演示；
- 固定统计尚未标明为虚拟示例；
- 手机网页可能被误认为已完成 App；
- PR 描述为空，缺少截图、运行说明和边界声明；
- 当前 CI 通过不足以证明新界面可验收。

建议先将 PR 定位为“手机网页视觉原型”，并在描述中明确：

- 已完成的视觉与交互；
- 仅为视觉占位的按钮；
- 固定演示数据；
- 尚未实现的真实认证、服务端保存、媒体调用与 App 安装；
- API 暂时断开的原因及恢复计划。

### 4.2 建议的 Git 协作路径

1. 将 PR #5 的目标分支改为 `feat/frontend-ux`；
2. Ivy 完成 CSS 基线拆分和移动端基线；
3. 用户从双方认可的最新 `feat/frontend-ux` 创建短分支 `feat/frontend-ux/desktop-web-v1`；
4. 用户主要修改 `desktop.css` 和桌面专用素材；
5. 手机与桌面共同验收后，再从 `feat/frontend-ux` 向 `main` 提交 PR。

### 4.3 建议的样式结构

```text
apps/web/src/
├─ app.js
├─ styles/
│  ├─ tokens.css
│  ├─ base.css
│  ├─ mobile.css
│  └─ desktop.css
├─ components/
└─ assets/
   ├─ shared/
   ├─ mobile/
   └─ desktop/
```

需要核验：该拆分是否适合当前代码，以及是否存在迁移成本更低的方案。

### 4.4 桌面端第一轮范围

用户第一轮仅实现：

1. 桌面工作台；
2. 桌面 AI 对话；
3. 桌面反馈卡。

桌面端重点使用左侧导航和多栏结构，将“对话历史—聊天—保存/权限状态”以及“反馈卡编辑—来源说明”并列展示，并补齐键盘焦点和鼠标悬停状态。

不得通过桌面 CSS 隐藏移动端已有的重要功能。

### 4.5 App 交付缺口

即使响应式 Web 完成，可安装 App 仍未交付。团队需要另行确认：

- 是否继续开发真正的 App；
- 负责人；
- 技术栈；
- 或是否正式调整交付范围。

## 五、建议行动清单

### 5.1 Ivy

1. 保持 `app.js` 单一维护权；
2. 将现有 CSS 整理为 `tokens/base/mobile/desktop`，或提出成本更低的替代结构；
3. 在 `tokens.css` 建立茶杏橄榄语义色值；
4. 将现有移动端样式归入移动端基线；
5. 为固定内容添加醒目的“虚拟示例”标识；
6. 恢复 `/api/comfort`，或在 PR 中明确断开原因和恢复计划；
7. 补充 390px 截图、运行说明和已知限制。

### 5.2 用户

1. 等待 Ivy 提供稳定的 CSS 基线提交；
2. 从双方认可的前端基线创建桌面短分支；
3. 只实现工作台、AI 对话和反馈卡的 1024–1440px 布局；
4. 不修改 `app.js`、API 字段和业务状态；
5. 提供 1440px、1024px、768px 截图供共同复核。

### 5.3 共同验收

- 茶杏橄榄 HEX 值一致；
- 移动端与桌面端文案一致；
- 五种内容状态含义一致且可区分；
- 三个隐私开关边界一致；
- 0 条记录时显示 0；
- 虚拟数据有显著标记；
- 两种布局调用同一 API；
- 正文字号、触控尺寸和键盘焦点符合最低要求。

## 六、不可擅自改变的边界

- 不把手机网页称为已完成 App；
- 不把 `localStorage` 登录称为真实账号系统；
- 不把固定能力值称为用户真实分析结果；
- 不因视觉开发擅自修改 OpenAPI 字段；
- 不由两人同时修改 `app.js`；
- 不把未经双方确认的配色写入共享 tokens；
- 不直接强推或覆盖 `main`。

## 七、请 Ivy 的 agent 回答

1. 上述仓库、PR #5、API、测试和数据保存现状是否准确？如不准确，请附文件或 GitHub 链接。
2. PR #5 是否应先进入 `feat/frontend-ux`，而不是直接进入 `main`？
3. Ivy 单独维护 `app.js`、用户只维护 `desktop.css`，是否足以避免冲突？
4. `tokens/base/mobile/desktop` 是否适合当前代码？是否有成本更低的拆分？
5. 桌面开发前是否必须整理八层 CSS？哪些文件应合并，哪些应保留？
6. 如何在不推翻现有视觉原型的情况下恢复 `/api/comfort`？
7. 固定报告、能力值和记忆数据应如何标记或隔离，才能落实“0 就是 0”？
8. 茶杏橄榄配色应一次性替换，还是先建立语义 tokens 再逐步迁移？
9. 用户何时可以安全创建 `desktop-web-v1` 分支？请列出明确的前置条件。
10. 手机网页与可安装 App 之间的交付缺口应如何记录和分工？
11. 如果反对上述方案，请提供冲突更低、可回退的替代路径。

## 八、期望的回复格式

请在结论中明确选择：

- `同意`
- `需要修订`
- `反对`

并分别列出：

1. 用户现在可以直接执行的动作；
2. 仍需等待 Ivy 完成的动作；
3. 关键风险及对应的回退方案。
