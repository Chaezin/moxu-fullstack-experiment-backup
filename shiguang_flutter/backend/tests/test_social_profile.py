import pytest
from httpx import AsyncClient


async def register(client: AsyncClient, phone: str) -> dict:
    response = await client.post(
        "/api/v1/auth/register", json={"phone": phone, "password": "StrongPass123"}
    )
    return response.json()


@pytest.mark.anyio
async def test_user_can_hide_profile_and_detail_is_scoped(client: AsyncClient) -> None:
    owner = await register(client, "13800138011")
    viewer = await register(client, "13800138012")
    owner_headers = {"Authorization": f"Bearer {owner['token']}"}
    viewer_headers = {"Authorization": f"Bearer {viewer['token']}"}
    profile = await client.patch(
        "/api/v1/me", headers=owner_headers,
        json={"name": "可见用户", "city": "上海", "bio": "公开介绍", "interests": "摄影,整理"},
    )
    owner_id = profile.json()["profile"]["id"]
    detail = await client.get(f"/api/v1/people/{owner_id}", headers=viewer_headers)
    assert detail.status_code == 200
    assert detail.json()["person"]["publicInterests"] == ["摄影", "整理"]
    hidden = await client.patch("/api/v1/me/visibility", headers=owner_headers, json={"public": False})
    assert hidden.status_code == 200
    unavailable = await client.get(f"/api/v1/people/{owner_id}", headers=viewer_headers)
    assert unavailable.status_code == 404
