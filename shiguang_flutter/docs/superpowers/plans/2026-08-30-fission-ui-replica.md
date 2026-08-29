# 拾光 Fission UI 复刻实施计划

> **For agentic workers:** UI-only implementation; preserve the local behavior layer and verify before completion.

**Goal:** 将 `shiguang-fission` 的毛毡风格页面视觉层同步到本地 Flutter WebView 资源，同时保留本地真实接口、语音输入、运行时配置和退出登录。

**Architecture:** 以参考仓库 `shiguang_flutter/assets/web` 的 CSS 与视觉素材作为展示层来源；本地 `app.js`、`demo-api.js`、`runtime-config.js`、`voice-input.js` 不覆盖，仅在 `index.html` 追加参考样式入口。

**Tech Stack:** 原生 HTML、CSS、JavaScript、Flutter WebView 资源清单、Node.js 内置测试。

## Global Constraints

- 仅修改 UI 入口、CSS 和视觉图片素材。
- 不修改本地业务行为脚本及后端接口。
- 保留 `runtime-config.js`、`demo-api.js`、`voice-input.js` 的加载顺序。
- 完成后运行现有 Web/语音测试和 UI 资源契约测试。

### Task 1: 同步参考视觉资源

**Files:**
- Modify: `assets/web/index.html`
- Replace: `assets/web/src/*.css`（与参考仓库同名的视觉样式）
- Add/Replace: `assets/web/src/assets/`、`assets/web/src/felt/` 视觉图片
- Add: `assets/web/test/fission-ui-contract.test.mjs`

- [x] 写入 UI 资源契约测试并确认缺失样式会失败。
- [x] 同步参考 CSS 与视觉素材。
- [x] 在入口中加载毛毡登录和应用样式，同时保留本地运行时脚本。
- [x] 运行 UI 契约测试和完整 Web 测试。
