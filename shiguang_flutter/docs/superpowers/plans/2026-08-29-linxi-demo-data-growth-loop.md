# 林溪演示数据与聊天成长闭环 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为林溪和四位同路人建立可重复初始化的数据库故事数据，并让后续聊天增量更新能力、成长卡片、探索方向、月报和同路人推荐。

**Architecture:** 保留现有 FastAPI、SQLAlchemy 和异步分析任务边界，新增独立的探索方向领域模型、匹配服务和演示数据初始化服务。初始化使用稳定逻辑键并在单一事务中合并缺失数据；聊天分析在原有能力/卡片流水线上追加方向候选，前端统一恢复和刷新成长数据。

**Tech Stack:** Python 3、FastAPI、SQLAlchemy 2、Pydantic、pytest、SQLite/PostgreSQL、原生 JavaScript。

## Global Constraints

- 演示数据只允许显式启用，不在生产启动时自动写入。
- 测试账号密码统一为 `Shiguang2026!`，只保存强哈希。
- 主账号为 `13800138000`，配角账号为 `13800138001` 至 `13800138004`。
- 初始化只补缺失数据，不覆盖林溪的非空资料和后续用户数据。
- 社交推荐只用于朋友、同路人和合作伙伴，不涉及婚恋。
- 探索方向不得承诺收入，统一使用“尝试”“探索”等措辞。
- 所有新文本和代码文件使用 UTF-8。

---

## 文件结构

- `backend/app/models.py`：增加探索方向及其证据模型。
- `backend/app/analysis.py`：定义方向候选，并让本地分析器返回保守的方向建议。
- `backend/app/ai.py`：扩展 AI 结构化输出解析。
- `backend/app/worker.py`：保存方向证据并增量合并方向。
- `backend/app/matching.py`：独立计算公开资料之间的匹配分数和推荐理由。
- `backend/app/demo_seed.py`：保存人物、故事和幂等初始化逻辑。
- `backend/seed_demo.py`：显式执行初始化的命令行入口。
- `backend/app/main.py`：提供方向 API，增强月报和同路人推荐。
- `assets/web/src/app.js`：登录及聊天后加载方向和最新月报。
- `backend/tests/test_directions.py`：方向模型、接口和账号隔离测试。
- `backend/tests/test_analysis.py`、`backend/tests/test_ai.py`、`backend/tests/test_growth_cards.py`：分析和 Worker 回归测试。
- `backend/tests/test_demo_seed.py`：初始化完整性、幂等性和不覆盖测试。
- `backend/tests/test_social.py`：推荐排序及隐私测试。
- `backend/tests/test_web_growth_contract.py`：页面数据加载契约测试。
- `README.md`、`backend/README.md`：演示账号和初始化命令说明。

### Task 1: 增加探索方向持久化模型

**Files:**
- Modify: `backend/app/models.py`
- Create: `backend/tests/test_directions.py`

**Interfaces:**
- Produces: `UserDirection`、`DirectionEvidence` SQLAlchemy 模型。
- Consumes: `Base`、`utc_now()`、现有 `User`、`Conversation`、`Message` 外键。

- [ ] **Step 1: 写模型建表失败测试**

```python
from sqlalchemy import inspect


def test_direction_tables_are_created(app) -> None:
    engine = app.state.session_factory.kw["bind"]
    tables = set(inspect(engine).get_table_names())
    assert {"user_directions", "direction_evidence"} <= tables
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_directions.py::test_direction_tables_are_created -v`

Expected: FAIL，缺少 `user_directions` 和 `direction_evidence`。

- [ ] **Step 3: 实现两个模型**

在 `backend/app/models.py` 增加：

```python
class UserDirection(Base):
    __tablename__ = "user_directions"
    __table_args__ = (
        UniqueConstraint("user_id", "normalized_title", name="uq_user_direction_title"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    normalized_title: Mapped[str] = mapped_column(String(160))
    title: Mapped[str] = mapped_column(String(160))
    summary: Mapped[str] = mapped_column(Text)
    confidence: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(16), default="active")
    visibility: Mapped[str] = mapped_column(String(16), default="visible")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class DirectionEvidence(Base):
    __tablename__ = "direction_evidence"
    __table_args__ = (
        UniqueConstraint("user_id", "fingerprint", name="uq_user_direction_evidence"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    direction_id: Mapped[str] = mapped_column(ForeignKey("user_directions.id", ondelete="CASCADE"), index=True)
    message_id: Mapped[str | None] = mapped_column(ForeignKey("messages.id", ondelete="SET NULL"), nullable=True, index=True)
    conversation_id: Mapped[str | None] = mapped_column(ForeignKey("conversations.id", ondelete="SET NULL"), nullable=True, index=True)
    summary: Mapped[str] = mapped_column(Text)
    score: Mapped[float] = mapped_column(Float)
    fingerprint: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_directions.py -v`

Expected: PASS。

- [ ] **Step 5: 提交**

```powershell
git add backend/app/models.py backend/tests/test_directions.py
git commit -m "feat: add growth direction models"
```

### Task 2: 扩展聊天分析并保存方向证据

**Files:**
- Modify: `backend/app/analysis.py`
- Modify: `backend/app/ai.py`
- Modify: `backend/app/worker.py`
- Modify: `backend/tests/test_analysis.py`
- Modify: `backend/tests/test_ai.py`
- Modify: `backend/tests/test_growth_cards.py`

**Interfaces:**
- Produces: `DirectionCandidate(title: str, summary: str, score: float)`；`AnalysisResult.directions`；`_save_new_directions(session, job, message, result)`。
- Consumes: Task 1 的 `UserDirection` 和 `DirectionEvidence`。

- [ ] **Step 1: 写方向解析和 Worker 增量更新失败测试**

```python
def test_keyword_analysis_finds_plant_service_direction() -> None:
    result = KeywordSkillExtractor().analyze("我帮邻居整理了阳台植物养护表，还收到了第一次服务费")
    assert [item.title for item in result.directions] == ["阳台植物照护服务"]


def test_ai_parses_directions() -> None:
    def request(url, headers, payload, timeout):
        return {"choices": [{"message": {"content": (
            '{"summary":"帮邻居解决植物问题","skills":[],'
            '"directions":[{"title":"阳台植物照护服务",'
            '"summary":"先从一次低风险服务开始验证", "score":0.82}]}'
        )}}]}
    ai = OpenAICompatibleAI(
        "https://example.test/v1", "secret", "model-x", request=request
    )
    result = ai.analyze("我帮邻居解决了植物养护问题")
    assert result.directions[0].title == "阳台植物照护服务"
    assert result.directions[0].score == 0.82


async def test_worker_persists_direction_evidence(client, app) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations", headers=headers, json={"title": "植物服务"}
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={
            "content": "我帮邻居整理了阳台植物养护表，还收到了第一次服务费",
            "clientMessageId": "direction-001",
        },
    )
    process_next_analysis_job(app.state.session_factory, KeywordSkillExtractor())
    response = await client.get("/api/v1/directions", headers=headers)
    assert response.json()["items"][0]["title"] == "阳台植物照护服务"
```

- [ ] **Step 2: 运行三个目标测试并确认失败**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_analysis.py backend/tests/test_ai.py backend/tests/test_growth_cards.py -q`

Expected: FAIL，`AnalysisResult` 没有 `directions`，方向未落库。

- [ ] **Step 3: 扩展分析领域类型和本地保守规则**

在 `backend/app/analysis.py` 增加：

```python
DIRECTION_THRESHOLD = 0.65


@dataclass(frozen=True)
class DirectionCandidate:
    title: str
    summary: str
    score: float


@dataclass(frozen=True)
class AnalysisResult:
    summary: str
    skills: tuple[SkillCandidate, ...]
    directions: tuple[DirectionCandidate, ...] = ()
```

本地分析器只在出现具体行动时生成方向：植物/养护/阳台与帮助、整理、服务或收费共同出现时生成“阳台植物照护服务”；教程/记录/内容与整理或制作共同出现时生成“家庭经验内容整理”；社区/交换/活动与组织或协助共同出现时生成“社区轻活动协作”。

- [ ] **Step 4: 扩展 AI JSON 协议并严格解析**

系统提示固定返回：

```json
{
  "summary": "不超过240字",
  "skills": [{"name": "技能名", "category": "通用能力", "score": 0.8}],
  "directions": [{"title": "探索方向", "summary": "低风险下一步，不承诺收入", "score": 0.7}]
}
```

解析时对 `directions` 使用 `parsed.get("directions", [])` 保持旧模型响应兼容，标题截断到 160 字，说明截断到 500 字，分数限制在 `0.0..1.0`。

- [ ] **Step 5: 在 Worker 中幂等保存方向和证据**

```python
def _save_new_directions(session, job, message, result) -> list[UserDirection]:
    saved = []
    for candidate in result.directions:
        if candidate.score < DIRECTION_THRESHOLD:
            continue
        normalized = candidate.title.casefold().strip()
        direction = session.scalar(select(UserDirection).where(
            UserDirection.user_id == job.user_id,
            UserDirection.normalized_title == normalized,
        ))
        if direction is None:
            direction = UserDirection(
                user_id=job.user_id,
                normalized_title=normalized,
                title=candidate.title,
                summary=candidate.summary,
                confidence=candidate.score,
            )
            session.add(direction)
            session.flush()
        else:
            direction.confidence = max(direction.confidence, candidate.score)
        fingerprint = sha256(
            f"{job.user_id}|direction|{normalized}|{result.summary}".encode("utf-8")
        ).hexdigest()
        if session.scalar(select(DirectionEvidence).where(
            DirectionEvidence.user_id == job.user_id,
            DirectionEvidence.fingerprint == fingerprint,
        )) is None:
            session.add(DirectionEvidence(
                user_id=job.user_id,
                direction_id=direction.id,
                message_id=message.id,
                conversation_id=message.conversation_id,
                summary=candidate.summary,
                score=candidate.score,
                fingerprint=fingerprint,
            ))
            saved.append(direction)
    return saved
```

在 `process_next_analysis_job()` 中与能力保存处于同一事务，并在卡片判断之外调用，确保没有高分技能时仍可保存合格方向。

- [ ] **Step 6: 运行分析与 Worker 测试**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_analysis.py backend/tests/test_ai.py backend/tests/test_growth_cards.py -q`

Expected: PASS。

- [ ] **Step 7: 提交**

```powershell
git add backend/app/analysis.py backend/app/ai.py backend/app/worker.py backend/tests/test_analysis.py backend/tests/test_ai.py backend/tests/test_growth_cards.py
git commit -m "feat: derive directions from chat evidence"
```

### Task 3: 提供方向、月报和可解释同路人推荐

**Files:**
- Create: `backend/app/matching.py`
- Modify: `backend/app/main.py`
- Modify: `backend/tests/test_directions.py`
- Modify: `backend/tests/test_social.py`

**Interfaces:**
- Produces: `build_match_reason(viewer_terms: set[str], person: User) -> tuple[int, str]`；`GET /api/v1/directions`。
- Consumes: `UserDirection`、`UserSkill` 和公开的 `User.interests`。

- [ ] **Step 1: 写方向隔离、月报方向关键词和推荐理由失败测试**

```python
@pytest.mark.anyio
async def test_directions_are_isolated_by_user(client, app) -> None:
    first = await client.post(
        "/api/v1/auth/register", json={"phone": "13800138031", "password": "StrongPass123"}
    )
    second = await client.post(
        "/api/v1/auth/register", json={"phone": "13800138032", "password": "StrongPass123"}
    )
    with app.state.session_factory() as session:
        session.add_all([
            UserDirection(
                user_id=first.json()["user"]["id"], normalized_title="阳台植物照护服务",
                title="阳台植物照护服务", summary="从一次低风险服务开始", confidence=0.82,
            ),
            UserDirection(
                user_id=second.json()["user"]["id"], normalized_title="手作内容",
                title="手作内容", summary="整理手作过程", confidence=0.77,
            ),
        ])
        session.commit()
    first_headers = {"Authorization": f"Bearer {first.json()['token']}"}
    first = await client.get("/api/v1/directions", headers=first_headers)
    assert [item["title"] for item in first.json()["items"]] == ["阳台植物照护服务"]


@pytest.mark.anyio
async def test_recommendations_include_explainable_match_reason(client) -> None:
    viewer = await client.post(
        "/api/v1/auth/register", json={"phone": "13800138041", "password": "StrongPass123"}
    )
    person = await client.post(
        "/api/v1/auth/register", json={"phone": "13800138042", "password": "StrongPass123"}
    )
    await client.patch(
        "/api/v1/me",
        headers={"Authorization": f"Bearer {viewer.json()['token']}"},
        json={"name": "林溪", "interests": "植物照护、社区分享"},
    )
    await client.patch(
        "/api/v1/me",
        headers={"Authorization": f"Bearer {person.json()['token']}"},
        json={"name": "周禾", "interests": "植物照护、自然观察"},
    )
    headers = {"Authorization": f"Bearer {viewer.json()['token']}"}
    result = await client.get("/api/v1/people/recommendations", headers=headers)
    person = result.json()["items"][0]
    assert person["matchScore"] > 0
    assert "植物" in person["matchReason"]
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_directions.py backend/tests/test_social.py -q`

Expected: FAIL，方向接口不存在且推荐没有理由。

- [ ] **Step 3: 实现匹配服务**

`backend/app/matching.py` 将中文顿号、逗号和空格统一切分；查看者词集合由公开兴趣、可见能力名和可见方向标题组成。候选账号只使用公开兴趣和简介，按精确词交集与关键词包含计算分数，并返回“你们都关注植物照护与社区分享”这样的理由；无交集时返回“你们都在认真整理生活经验”，分数为 `0`。

- [ ] **Step 4: 实现方向接口并增强推荐/月报**

```python
@app.get("/api/v1/directions")
def list_directions(user=Depends(get_current_user), session=Depends(get_session)) -> dict:
    directions = session.scalars(select(UserDirection).where(
        UserDirection.user_id == user.id,
        UserDirection.status == "active",
        UserDirection.visibility == "visible",
    ).order_by(UserDirection.confidence.desc(), UserDirection.title)).all()
    return {"items": [{
        "id": item.id,
        "title": item.title,
        "summary": item.summary,
        "confidence": item.confidence,
    } for item in directions]}
```

推荐接口批量读取当前用户可见能力和方向，计算每个公开候选人的 `matchScore`、`matchReason` 后稳定排序。月报关键词先取当月卡片关联能力，再补充当前高置信方向，去重后最多四项；摘要增加“正在尝试 N 个方向”，但不描述收益保证。

删除会话时，与现有 `SkillEvidence` 清理保持一致，把属于当前用户和该会话的 `DirectionEvidence.message_id`、`DirectionEvidence.conversation_id` 置空；增加测试确认方向摘要保留但原文引用不可再访问。

- [ ] **Step 5: 运行方向和社交测试**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_directions.py backend/tests/test_social.py -q`

Expected: PASS。

- [ ] **Step 6: 提交**

```powershell
git add backend/app/matching.py backend/app/main.py backend/tests/test_directions.py backend/tests/test_social.py
git commit -m "feat: expose directions and explain friend matches"
```

### Task 4: 创建幂等的林溪故事初始化服务

**Files:**
- Create: `backend/app/demo_seed.py`
- Create: `backend/seed_demo.py`
- Create: `backend/tests/test_demo_seed.py`

**Interfaces:**
- Produces: `seed_demo_data(session: Session, now: datetime | None = None) -> SeedReport`；`SeedReport(created: Counter[str], skipped: Counter[str])`。
- Consumes: 现有安全哈希函数和全部业务模型，包括 Task 1 的方向模型。

- [ ] **Step 1: 写完整性、幂等性和不覆盖失败测试**

```python
def test_seed_creates_complete_linxi_story(session_factory) -> None:
    with session_factory() as session:
        report = seed_demo_data(session, now=datetime(2026, 8, 29, tzinfo=timezone.utc))
        session.commit()
    with session_factory() as session:
        assert session.scalar(select(func.count(User.id))) == 5
        assert session.scalar(select(func.count(Conversation.id))) == 5
        assert session.scalar(select(func.count(Message.id))) == 10
        assert session.scalar(select(func.count(UserSkill.id))) == 5
        assert session.scalar(select(func.count(SkillEvidence.id))) == 5
        assert session.scalar(select(func.count(GrowthCard.id))) == 4
        assert session.scalar(select(func.count(UserDirection.id))) == 3
        assert session.scalar(select(func.count(DirectionEvidence.id))) == 3
        assert session.scalar(select(func.count(DirectConversation.id))) == 3
        assert session.scalar(select(func.count(DirectMessage.id))) == 6
        users = session.scalars(select(User).order_by(User.phone)).all()
        assert all(verify_password("Shiguang2026!", user.password_hash) for user in users)


def test_seed_is_idempotent_and_preserves_nonempty_profile(session_factory) -> None:
    with session_factory() as session:
        seed_demo_data(session, now=datetime(2026, 8, 29, tzinfo=timezone.utc))
        linxi = session.scalar(select(User).where(User.phone == "13800138000"))
        linxi.bio = "用户后来填写的简介"
        session.commit()
    with session_factory() as session:
        second = seed_demo_data(session, now=datetime(2026, 8, 29, tzinfo=timezone.utc))
        session.commit()
        linxi = session.scalar(select(User).where(User.phone == "13800138000"))
    assert second.created.total() == 0
    assert linxi.bio == "用户后来填写的简介"
```

测试文件增加本地 fixture：

```python
@pytest.fixture
def session_factory(tmp_path):
    return build_session_factory(f"sqlite:///{(tmp_path / 'seed.db').as_posix()}")
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_demo_seed.py -q`

Expected: FAIL，初始化模块尚不存在。

- [ ] **Step 3: 定义稳定 ID、人物和故事清单**

在 `backend/app/demo_seed.py` 使用固定 UUID namespace 和 `uuid5(namespace, logical_key)`。人物清单固定为林溪、周禾、陈屿、许清、唐宁；五组对话标题固定为：

```python
CONVERSATIONS = (
    ("daily-no-direction", "忙了一天，却不知道为了什么", -45),
    ("mint-recovery", "救回阳台上的薄荷", -32),
    ("neighbor-care-sheet", "给邻居做了一张养护表", -21),
    ("plant-swap", "第一次协助植物交换活动", -12),
    ("first-small-payment", "收到第一笔小额服务费", -5),
)
```

每组写入一条林溪用户消息和一条助手回应；能力固定为“细致观察、持续照护、分类整理、经验表达、活动协调”；成长卡片固定四张；方向固定为“阳台植物照护服务、家庭经验内容整理、社区轻活动协作”。三组私信分别关联周禾、陈屿和许清，每组一来一回。

- [ ] **Step 4: 实现单事务合并逻辑**

```python
def seed_demo_data(session: Session, now: datetime | None = None) -> SeedReport:
    anchor = now or datetime.now(timezone.utc)
    report = SeedReport()
    users = _ensure_users(session, report)
    messages = _ensure_story_conversations(session, users["linxi"], anchor, report)
    skills = _ensure_skills_and_evidence(session, users["linxi"], messages, anchor, report)
    _ensure_cards(session, users["linxi"], messages, skills, anchor, report)
    _ensure_directions(session, users["linxi"], messages, anchor, report)
    _ensure_direct_messages(session, users, anchor, report)
    session.flush()
    return report
```

所有 `_ensure_*` 先按手机号、稳定主键或现有唯一业务键查询；存在时记录 `skipped`，不存在时记录 `created`。用户资料只对空字符串字段赋默认值。函数内部不提交，由 CLI 或调用方统一 `commit()`；异常自然触发调用方 `rollback()`。

- [ ] **Step 5: 实现显式允许的 CLI**

```python
def main() -> None:
    parser = argparse.ArgumentParser(description="初始化拾光演示账号与故事数据")
    parser.add_argument("--allow-demo-data", action="store_true")
    args = parser.parse_args()
    if not args.allow_demo_data and os.getenv("SHIGUANG_ALLOW_DEMO_DATA") != "1":
        raise SystemExit("拒绝执行：请显式传入 --allow-demo-data")
    session_factory = build_session_factory(os.getenv("SHIGUANG_DATABASE_URL", "sqlite:///./shiguang.db"))
    with session_factory() as session:
        try:
            report = seed_demo_data(session)
            session.commit()
        except Exception:
            session.rollback()
            raise
    print(report.as_text())
```

- [ ] **Step 6: 运行初始化测试**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_demo_seed.py -q`

Expected: PASS，第二次初始化新增数为 0。

- [ ] **Step 7: 提交**

```powershell
git add backend/app/demo_seed.py backend/seed_demo.py backend/tests/test_demo_seed.py
git commit -m "feat: seed coherent linxi demo story"
```

### Task 5: 连接页面的方向和月报刷新

**Files:**
- Modify: `assets/web/src/app.js`
- Create: `backend/tests/test_web_growth_contract.py`

**Interfaces:**
- Consumes: `GET /api/v1/directions`、`GET /api/v1/reports/monthly`。
- Produces: 登录恢复与聊天完成后的 `state.directions`、`state.monthlyReport` 最新状态。

- [ ] **Step 1: 写页面契约失败测试**

```python
from pathlib import Path


def test_web_hydrates_and_refreshes_directions_and_report() -> None:
    source = Path("assets/web/src/app.js").read_text(encoding="utf-8")
    hydrate = source[source.index("async function hydrateAccount"):source.index("async function refreshGrowthData")]
    refresh = source[source.index("async function refreshGrowthData"):source.index("async function hydrateSchedule")]
    assert "/api/v1/directions" in hydrate
    assert "state.directions=directionResult.items||[]" in hydrate
    assert "/api/v1/directions" in refresh
    assert "/api/v1/reports/monthly" in refresh
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_web_growth_contract.py -q`

Expected: FAIL，登录逻辑仍把方向清空，刷新逻辑只加载卡片和能力。

- [ ] **Step 3: 更新登录恢复和成长数据刷新**

`hydrateAccount()` 的 `Promise.all` 增加 `/api/v1/directions`，并赋值：

```javascript
state.directions=directionResult.items||directionResult.directions||[];
```

`refreshGrowthData()` 并行读取卡片、能力、方向和当前月报：

```javascript
const [cardResult,skillResult,directionResult,reportResult]=await Promise.all([
  apiRequest('/api/v1/cards'),
  apiRequest('/api/v1/skills'),
  apiRequest('/api/v1/directions'),
  apiRequest(`/api/v1/reports/monthly?month=${new Date().toISOString().slice(0,7)}`)
]);
state.directions=directionResult.items||directionResult.directions||[];
state.monthlyReport=reportResult.report||null;
```

- [ ] **Step 4: 运行页面契约测试**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_web_growth_contract.py -q`

Expected: PASS。

- [ ] **Step 5: 提交**

```powershell
git add assets/web/src/app.js backend/tests/test_web_growth_contract.py
git commit -m "feat: refresh growth directions in web app"
```

### Task 6: 文档、全量验证与更新本地数据库

**Files:**
- Modify: `README.md`
- Modify: `backend/README.md`
- Runtime update, not committed: `backend/shiguang.db`

**Interfaces:**
- Consumes: Task 4 的 `backend/seed_demo.py`。
- Produces: 已填充的本地开发数据库和可复现操作说明。

- [ ] **Step 1: 更新使用说明**

在根 README 列出五个演示手机号、统一密码及“这些账号仅用于本地演示”。在后端 README 增加：

```powershell
.venv\Scripts\python.exe seed_demo.py --allow-demo-data
```

说明命令可重复运行、只补缺失数据，并尊重 `SHIGUANG_DATABASE_URL`。

- [ ] **Step 2: 运行后端全量测试**

Run: `backend/.venv/Scripts/python.exe -m pytest backend/tests -q`

Expected: 全部 PASS，无失败或错误。

- [ ] **Step 3: 运行 Flutter 静态检查和测试**

Run: `.tooling/flutter/bin/flutter analyze`

Expected: `No issues found!`

Run: `.tooling/flutter/bin/flutter test`

Expected: 全部 PASS。

- [ ] **Step 4: 更新实际本地后端数据库**

在 `backend` 目录执行，确保默认连接的是 `backend/shiguang.db`：

Run: `.venv/Scripts/python.exe seed_demo.py --allow-demo-data`

Expected: 首次输出 5 个账号、5 个会话、10 条消息、5 项能力、5 条能力证据、4 张卡片、3 个方向、3 条方向证据、3 个私信会话和 6 条私信的创建统计；若部分数据已存在则对应显示为跳过。

- [ ] **Step 5: 再次执行验证幂等性**

Run: `.venv/Scripts/python.exe seed_demo.py --allow-demo-data`

Expected: 所有业务记录新增数均为 0，现有数量不变。

- [ ] **Step 6: 验证真实数据库记录总数**

使用 `backend/shiguang.db` 查询实际写入结果：

Run:

```powershell
.venv/Scripts/python.exe -c "from sqlalchemy import func,select; from app.database import build_session_factory; from app.models import User,Conversation,Message,UserSkill,GrowthCard,UserDirection; sf=build_session_factory('sqlite:///./shiguang.db'); s=sf(); print({'users':s.scalar(select(func.count(User.id))),'conversations':s.scalar(select(func.count(Conversation.id))),'messages':s.scalar(select(func.count(Message.id))),'skills':s.scalar(select(func.count(UserSkill.id))),'cards':s.scalar(select(func.count(GrowthCard.id))),'directions':s.scalar(select(func.count(UserDirection.id)))}); s.close()"
```

Expected: 输出字典中的总数至少满足以下下限，并与初始化命令输出一致：

```text
users >= 5
conversations >= 5
messages >= 10
skills >= 5
cards >= 4
directions >= 3
```

- [ ] **Step 7: 提交文档**

```powershell
git add README.md backend/README.md
git commit -m "docs: explain demo story initialization"
```

- [ ] **Step 8: 最终检查工作区**

Run: `git status --short`

Expected: 仅保留任务开始前已经存在的 `.planning/` 未跟踪目录；数据库文件受 `.gitignore` 管理，不进入提交。
