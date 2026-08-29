import pytest
from fastapi import FastAPI
from httpx import AsyncClient

from app.analysis import KeywordSkillExtractor
from app.worker import process_all_analysis_jobs
from tests.test_conversations import register_user


async def prepare_growth(app: FastAPI, client: AsyncClient) -> tuple[dict[str, str], str]:
    token = await register_user(client, "13800138081")
    headers = {"Authorization": f"Bearer {token}"}
    await client.patch(
        "/api/v1/me",
        headers=headers,
        json={"name": "小林", "city": "上海", "bio": "喜欢记录生活", "interests": "植物照护、摄影"},
    )
    conversation = await client.post("/api/v1/conversations", headers=headers, json={"title": "探索"})
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了 Flutter 页面。", "clientMessageId": "insight-1"},
    )
    process_all_analysis_jobs(app.state.session_factory, KeywordSkillExtractor())
    skill = (await client.get("/api/v1/skills", headers=headers)).json()["items"][0]
    return headers, skill["id"]


@pytest.mark.anyio
async def test_skill_detail_is_built_from_real_evidence(app: FastAPI, client: AsyncClient) -> None:
    headers, skill_id = await prepare_growth(app, client)

    response = await client.get(f"/api/v1/skills/{skill_id}", headers=headers)

    assert response.status_code == 200
    detail = response.json()["skill"]
    assert detail["name"] == "Flutter 开发"
    assert detail["typicalBehaviors"]
    assert detail["suitableScenarios"]
    assert detail["boundaries"]
    assert detail["evidence"]


@pytest.mark.anyio
async def test_refresh_directions_persists_personalized_results(
    app: FastAPI, client: AsyncClient
) -> None:
    headers, _ = await prepare_growth(app, client)

    refreshed = await client.post("/api/v1/directions/refresh", headers=headers)
    loaded = await client.get("/api/v1/directions", headers=headers)

    assert refreshed.status_code == 200
    assert len(refreshed.json()["items"]) >= 1
    assert loaded.json() == refreshed.json()
    assert "Flutter" in refreshed.json()["items"][0]["summary"]
