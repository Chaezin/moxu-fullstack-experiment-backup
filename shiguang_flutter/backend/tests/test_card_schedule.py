from datetime import datetime, timezone

import pytest
from fastapi import FastAPI
from httpx import AsyncClient
from sqlalchemy import select

from app.analysis import KeywordSkillExtractor
from app.models import AnalysisJob
from app.scheduler import run_due_schedules
from tests.test_conversations import register_user


@pytest.mark.anyio
async def test_user_can_save_and_reload_card_schedule(client: AsyncClient) -> None:
    token = await register_user(client, "13800138071")
    headers = {"Authorization": f"Bearer {token}"}

    saved = await client.put(
        "/api/v1/settings/card-schedule",
        headers=headers,
        json={"enabled": True, "localTime": "21:30", "timezone": "Asia/Shanghai"},
    )
    loaded = await client.get("/api/v1/settings/card-schedule", headers=headers)

    assert saved.status_code == 200
    assert loaded.json()["schedule"] == {
        "enabled": True,
        "localTime": "21:30",
        "timezone": "Asia/Shanghai",
        "lastRunDate": None,
    }


@pytest.mark.anyio
async def test_due_schedule_runs_once_per_local_day(
    app: FastAPI, client: AsyncClient
) -> None:
    token = await register_user(client, "13800138072")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations", headers=headers, json={"title": "每日整理"}
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了 Flutter 页面。", "clientMessageId": "scheduled-1"},
    )
    await client.put(
        "/api/v1/settings/card-schedule",
        headers=headers,
        json={"enabled": True, "localTime": "21:30", "timezone": "Asia/Shanghai"},
    )
    now = datetime(2026, 8, 29, 13, 31, tzinfo=timezone.utc)

    first = run_due_schedules(app.state.session_factory, KeywordSkillExtractor(), now)
    second = run_due_schedules(app.state.session_factory, KeywordSkillExtractor(), now)

    assert first == 1
    assert second == 0
    with app.state.session_factory() as session:
        assert session.scalar(select(AnalysisJob)).status == "completed"


@pytest.mark.anyio
async def test_disabled_schedule_does_not_run(app: FastAPI, client: AsyncClient) -> None:
    token = await register_user(client, "13800138073")
    headers = {"Authorization": f"Bearer {token}"}
    await client.put(
        "/api/v1/settings/card-schedule",
        headers=headers,
        json={"enabled": False, "localTime": "21:30", "timezone": "Asia/Shanghai"},
    )

    count = run_due_schedules(
        app.state.session_factory,
        KeywordSkillExtractor(),
        datetime(2026, 8, 29, 13, 31, tzinfo=timezone.utc),
    )

    assert count == 0
