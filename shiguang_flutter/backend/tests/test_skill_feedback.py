import pytest
from fastapi import FastAPI
from httpx import AsyncClient

from app.analysis import KeywordSkillExtractor
from app.worker import process_all_analysis_jobs
from tests.test_conversations import register_user


async def create_skill(app: FastAPI, client: AsyncClient, phone: str) -> tuple[dict, dict[str, str]]:
    token = await register_user(client, phone)
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations", headers=headers, json={"title": "能力反馈"}
    )
    await client.post(
        f"/api/v1/conversations/{conversation.json()['id']}/messages",
        headers=headers,
        json={"content": "我完成了 Flutter 页面。", "clientMessageId": f"skill-{phone}"},
    )
    process_all_analysis_jobs(app.state.session_factory, KeywordSkillExtractor())
    skills = await client.get("/api/v1/skills", headers=headers)
    return skills.json()["items"][0], headers


@pytest.mark.anyio
async def test_user_can_confirm_correct_and_hide_skill_with_history(
    app: FastAPI, client: AsyncClient
) -> None:
    skill, headers = await create_skill(app, client, "13800138051")

    confirmed = await client.patch(
        f"/api/v1/skills/{skill['id']}",
        headers=headers,
        json={"feedback": "confirmed"},
    )
    corrected = await client.patch(
        f"/api/v1/skills/{skill['id']}",
        headers=headers,
        json={"name": "Flutter 界面开发", "category": "技术", "feedback": "corrected"},
    )
    hidden = await client.patch(
        f"/api/v1/skills/{skill['id']}",
        headers=headers,
        json={"visibility": "hidden", "feedback": "hidden"},
    )
    visible = await client.get("/api/v1/skills", headers=headers)
    all_skills = await client.get("/api/v1/skills?includeHidden=true", headers=headers)
    history = await client.get(
        f"/api/v1/skills/{skill['id']}/history", headers=headers
    )

    assert confirmed.status_code == 200
    assert corrected.json()["name"] == "Flutter 界面开发"
    assert hidden.json()["visibility"] == "hidden"
    assert visible.json()["items"] == []
    assert all_skills.json()["items"][0]["visibility"] == "hidden"
    assert [item["action"] for item in history.json()["items"]] == [
        "hidden", "corrected", "confirmed"
    ]


@pytest.mark.anyio
async def test_skill_feedback_is_user_isolated(app: FastAPI, client: AsyncClient) -> None:
    skill, _ = await create_skill(app, client, "13800138052")
    _, other_headers = await create_skill(app, client, "13800138053")

    update = await client.patch(
        f"/api/v1/skills/{skill['id']}",
        headers=other_headers,
        json={"feedback": "confirmed"},
    )
    history = await client.get(
        f"/api/v1/skills/{skill['id']}/history", headers=other_headers
    )

    assert update.status_code == 404
    assert history.status_code == 404
