import asyncio

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.analysis import KeywordSkillExtractor
from app.main import create_app
from app.models import AnalysisJob
from app.worker import process_all_analysis_jobs, process_next_analysis_job
from tests.test_conversations import register_user


@pytest.mark.anyio
async def test_worker_generates_card_and_skills_after_threshold(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "成长记录"},
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={
            "content": "今天我完成了 Flutter demo，并练习了 presentation 演讲。",
            "clientMessageId": "growth-001",
        },
    )

    processed = process_next_analysis_job(
        app.state.session_factory,
        KeywordSkillExtractor(),
    )
    cards = await client.get("/api/v1/cards", headers=headers)
    skills = await client.get("/api/v1/skills", headers=headers)

    assert processed is True
    assert len(cards.json()["items"]) == 1
    assert cards.json()["items"][0]["source"] == "ai_auto"
    assert {item["name"] for item in skills.json()["items"]} >= {"Flutter 开发", "公众表达"}


@pytest.mark.anyio
async def test_worker_does_not_generate_card_for_skill_mention_only(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "普通闲聊"},
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我对 Flutter 有点兴趣。", "clientMessageId": "low-001"},
    )

    process_next_analysis_job(app.state.session_factory, KeywordSkillExtractor())
    cards = await client.get("/api/v1/cards", headers=headers)

    assert cards.json()["items"] == []


class FailingExtractor:
    def analyze(self, content: str):
        raise RuntimeError("temporary analyzer outage")


@pytest.mark.anyio
async def test_failed_analysis_retries_three_times_then_stops(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "重试测试"},
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了 Flutter 练习。", "clientMessageId": "retry-001"},
    )

    for _ in range(3):
        assert process_next_analysis_job(app.state.session_factory, FailingExtractor()) is True

    with app.state.session_factory() as session:
        job = session.scalar(select(AnalysisJob))
        assert job is not None
        assert job.status == "failed"
        assert job.attempts == 3


@pytest.mark.anyio
async def test_deleting_chat_keeps_card_but_removes_source_reference(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "可删除来源"},
    )
    conversation_id = conversation.json()["id"]
    await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"content": "今天我完成了 Flutter demo。", "clientMessageId": "delete-source-001"},
    )
    process_next_analysis_job(app.state.session_factory, KeywordSkillExtractor())
    before_delete = await client.get("/api/v1/cards", headers=headers)

    await client.delete(f"/api/v1/conversations/{conversation_id}", headers=headers)
    after_delete = await client.get("/api/v1/cards", headers=headers)

    assert len(before_delete.json()["items"]) == 1
    assert before_delete.json()["items"][0]["sourceAvailable"] is True
    assert len(after_delete.json()["items"]) == 1
    assert after_delete.json()["items"][0]["sourceAvailable"] is False


@pytest.mark.anyio
async def test_user_can_edit_and_delete_generated_card(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "卡片纠错"},
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了演讲练习。", "clientMessageId": "card-edit-001"},
    )
    process_next_analysis_job(app.state.session_factory, KeywordSkillExtractor())
    cards = await client.get("/api/v1/cards", headers=headers)
    card_id = cards.json()["items"][0]["id"]

    edited = await client.patch(
        f"/api/v1/cards/{card_id}",
        headers=headers,
        json={"title": "我的表达练习", "summary": "完成了一次演讲练习。"},
    )
    deleted = await client.delete(f"/api/v1/cards/{card_id}", headers=headers)
    remaining = await client.get("/api/v1/cards", headers=headers)

    assert edited.status_code == 200
    assert edited.json()["title"] == "我的表达练习"
    assert deleted.status_code == 204
    assert remaining.json()["items"] == []


@pytest.mark.anyio
async def test_posting_message_triggers_automatic_background_card(tmp_path) -> None:
    database_url = f"sqlite:///{(tmp_path / 'auto.db').as_posix()}"
    app = create_app(
        database_url=database_url,
        secret_key="test-secret-key-with-at-least-32-bytes",
        analysis_extractor=KeywordSkillExtractor(),
        enable_background_analysis=True,
    )
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        token = await register_user(client, "13800138000")
        headers = {"Authorization": f"Bearer {token}"}
        conversation = await client.post(
            "/api/v1/conversations",
            headers=headers,
            json={"title": "自动分析"},
        )

        await client.post(
            f"/api/v1/conversations/{conversation.json()['id']}/messages",
            headers=headers,
            json={"content": "我完成了 Flutter demo。", "clientMessageId": "auto-001"},
        )
        cards = await client.get("/api/v1/cards", headers=headers)

    assert len(cards.json()["items"]) == 1


@pytest.mark.anyio
async def test_daily_reconciliation_drains_pending_analysis_jobs(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "每日补偿"},
    )
    url = f"/api/v1/conversations/{conversation.json()['id']}/messages"
    await client.post(
        url,
        headers=headers,
        json={"content": "上午我完成了 Flutter 页面。", "clientMessageId": "daily-001"},
    )
    await client.post(
        url,
        headers=headers,
        json={"content": "下午我练习了演讲表达。", "clientMessageId": "daily-002"},
    )

    processed_count = process_all_analysis_jobs(
        app.state.session_factory,
        KeywordSkillExtractor(),
    )

    assert processed_count == 2


@pytest.mark.anyio
async def test_card_detail_and_monthly_report_use_real_evidence(
    app: FastAPI,
    client: AsyncClient,
) -> None:
    token = await register_user(client, "13800139998")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations", headers=headers, json={"title": "报告测试"}
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了 Flutter 页面。", "clientMessageId": "report-001"},
    )
    await asyncio.sleep(0.05)
    process_all_analysis_jobs(app.state.session_factory, KeywordSkillExtractor())
    cards = await client.get("/api/v1/cards", headers=headers)
    card_id = cards.json()["items"][0]["id"]
    detail = await client.get(f"/api/v1/cards/{card_id}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["evidence"]
    report = await client.get(
        "/api/v1/reports/monthly?month=2026-08", headers=headers
    )
    assert report.status_code == 200
    assert report.json()["report"]["cardCount"] >= 1
