import pytest
from fastapi import FastAPI
from httpx import AsyncClient

from app.analysis import KeywordSkillExtractor
from app.worker import process_all_analysis_jobs
from tests.test_conversations import register_user


async def create_card(app: FastAPI, client: AsyncClient, phone: str) -> tuple[str, dict[str, str]]:
    token = await register_user(client, phone)
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations", headers=headers, json={"title": "卡片撤销"}
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了 Flutter 页面。", "clientMessageId": f"card-{phone}"},
    )
    process_all_analysis_jobs(app.state.session_factory, KeywordSkillExtractor())
    cards = await client.get("/api/v1/cards", headers=headers)
    return cards.json()["items"][0]["id"], headers


@pytest.mark.anyio
async def test_user_can_undo_and_restore_growth_card(
    app: FastAPI, client: AsyncClient
) -> None:
    card_id, headers = await create_card(app, client, "13800138061")

    undone = await client.post(f"/api/v1/cards/{card_id}/undo", headers=headers)
    after_undo = await client.get("/api/v1/cards", headers=headers)
    restored = await client.post(f"/api/v1/cards/{card_id}/restore", headers=headers)
    after_restore = await client.get("/api/v1/cards", headers=headers)
    history = await client.get(f"/api/v1/cards/{card_id}/history", headers=headers)

    assert undone.status_code == 200
    assert undone.json()["status"] == "undone"
    assert after_undo.json()["items"] == []
    assert restored.status_code == 200
    assert restored.json()["status"] == "active"
    assert len(after_restore.json()["items"]) == 1
    assert [item["action"] for item in history.json()["items"]] == ["restored", "undone"]


@pytest.mark.anyio
async def test_card_lifecycle_is_user_isolated(app: FastAPI, client: AsyncClient) -> None:
    card_id, _ = await create_card(app, client, "13800138062")
    _, other_headers = await create_card(app, client, "13800138063")

    response = await client.post(f"/api/v1/cards/{card_id}/undo", headers=other_headers)

    assert response.status_code == 404
