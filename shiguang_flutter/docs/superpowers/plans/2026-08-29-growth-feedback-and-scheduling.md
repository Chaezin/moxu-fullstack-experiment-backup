# 成长档案纠错与定时整理实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成能力确认/纠错/隐藏、卡片撤销/恢复，以及按用户时间执行的每日补偿整理。

**Architecture:** 在现有 FastAPI 模块化单体中增加审计模型和用户调度设置；所有写操作均从访问令牌取得用户身份。前端继续通过现有 `apiRequest` 调用接口，调度执行由可重复、安全幂等的 Python runner 完成。

**Tech Stack:** Python 3.12、FastAPI、SQLAlchemy、SQLite/PostgreSQL、原生 JavaScript、pytest、Node test runner。

## Global Constraints

- 不信任客户端传入的用户 ID，所有资源必须校验归属。
- 自动卡片可撤销并恢复；能力可确认、修正、隐藏，所有变化保留审计记录。
- 定时任务按用户时区和本地时间判断到期，同一天最多成功执行一次。
- 先写失败测试并确认失败，再写最小实现。
- 不提交本地密钥和 `.planning` 文件。

---

### Task 1: 能力反馈与审计

**Files:**
- Modify: `backend/app/models.py`
- Modify: `backend/app/schemas.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_skill_feedback.py`

**Interfaces:**
- Produces: `PATCH /api/v1/skills/{skill_id}`，接受 `name/category/visibility/feedback`；`GET /api/v1/skills/{skill_id}/history`。

- [ ] 写失败测试：确认、修正、隐藏只影响当前用户，历史记录包含操作前后快照。
- [ ] 运行 `pytest backend/tests/test_skill_feedback.py -q`，确认因接口缺失失败。
- [ ] 增加 `UserSkill.visibility`、`SkillRevision` 模型和请求 schema。
- [ ] 实现更新与历史查询接口，列表默认不返回隐藏能力，可用 `includeHidden=true` 查询。
- [ ] 运行目标测试和完整后端测试。
- [ ] 提交 `feat: add skill feedback and revision history`。

### Task 2: 成长卡片撤销与恢复

**Files:**
- Modify: `backend/app/models.py`
- Modify: `backend/app/schemas.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_card_lifecycle.py`

**Interfaces:**
- Produces: `POST /api/v1/cards/{card_id}/undo`、`POST /api/v1/cards/{card_id}/restore`，卡片状态为 `active/undone/deleted`。

- [ ] 写失败测试：撤销后不出现在默认列表，恢复后重新出现，跨用户操作返回 404。
- [ ] 运行目标测试确认接口缺失。
- [ ] 实现状态转换并记录 `GrowthCardRevision`。
- [ ] 运行目标测试和完整后端测试。
- [ ] 提交 `feat: support undoing generated growth cards`。

### Task 3: 前端成长档案交互

**Files:**
- Modify: `assets/web/src/app.js`
- Modify: `assets/web/test/app-behavior.test.js`

**Interfaces:**
- Consumes: Task 1 与 Task 2 API。
- Produces: 能力确认、修正、隐藏和卡片撤销按钮的真实交互。

- [ ] 写失败测试：页面不再出现无事件的静态反馈按钮，包含真实 API 路径与刷新行为。
- [ ] 运行 Node 测试确认失败。
- [ ] 接入按钮事件、输入校验、错误提示和数据刷新。
- [ ] 运行前端测试与后端回归。
- [ ] 提交 `feat: connect growth feedback controls`。

### Task 4: 用户调度设置与到期判断

**Files:**
- Modify: `backend/app/models.py`
- Modify: `backend/app/schemas.py`
- Modify: `backend/app/main.py`
- Create: `backend/app/scheduler.py`
- Create: `backend/tests/test_card_schedule.py`

**Interfaces:**
- Produces: `GET/PUT /api/v1/settings/card-schedule`；`run_due_schedules(session_factory, extractor, now)`。

- [ ] 写失败测试：保存时区与本地时间、禁用设置、到期执行、同日幂等。
- [ ] 运行目标测试确认失败。
- [ ] 增加 `CardSchedule`、`ScheduledRun` 模型与接口。
- [ ] 实现按 IANA 时区判断到期并调用现有分析任务处理器。
- [ ] 运行目标测试和完整后端测试。
- [ ] 提交 `feat: schedule daily growth analysis`。

### Task 5: 调度入口、前端设置与验收

**Files:**
- Create: `backend/scheduler_cli.py`
- Modify: `assets/web/src/app.js`
- Modify: `assets/web/test/app-behavior.test.js`
- Modify: `backend/README.md`

**Interfaces:**
- Consumes: Task 4 调度接口与 runner。
- Produces: 可由系统计划任务周期调用的 CLI；登录后加载并保存用户设置。

- [ ] 写失败测试：前端从后端加载并保存调度设置。
- [ ] 接入前端设置 API，移除仅 localStorage 的权威行为。
- [ ] 增加一次性调度 CLI 和 Windows/生产调用说明。
- [ ] 运行后端全量测试、前端测试、`git diff --check` 和本地健康检查。
- [ ] 重启服务并在页面验证刷新后设置仍保留。
- [ ] 提交 `feat: complete automatic growth scheduling`。
