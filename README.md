# 模序前后端协作实验

这是一个最小但真实可运行的前后端实验：网页把 `event` 发送给后端，后端按共同契约返回 `reply` 和 `actions`。

## 本地运行

```bash
npm run dev
```

访问 `http://127.0.0.1:4173`。

## 两个人怎么共同开发

- UI/UX：从 `main` 创建 `feat/ux-v1`，主要修改 `apps/web/`。
- 后端：从 `main` 创建 `feat/api-v1`，主要修改 `apps/api/`。
- 共同格式：修改 `packages/contracts/openapi.yaml` 必须同时更新测试并在 PR 中说明。
- PR 的自动检查通过后再合并，避免一方改坏另一方。
