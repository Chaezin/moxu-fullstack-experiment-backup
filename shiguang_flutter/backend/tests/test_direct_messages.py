import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_direct_messages_persist_between_requests(client: AsyncClient) -> None:
    owner = await client.post("/api/v1/auth/register", json={"phone": "13800138021", "password": "StrongPass123"})
    viewer = await client.post("/api/v1/auth/register", json={"phone": "13800138022", "password": "StrongPass123"})
    owner_headers = {"Authorization": f"Bearer {owner.json()['token']}"}
    viewer_headers = {"Authorization": f"Bearer {viewer.json()['token']}"}
    profile = await client.patch("/api/v1/me", headers=owner_headers, json={"name": "聊天对象"})
    person_id = profile.json()["profile"]["id"]
    sent = await client.post(f"/api/v1/people/{person_id}/messages", headers=viewer_headers, json={"content": "你好", "clientMessageId": "direct-1"})
    assert sent.status_code == 200
    history = await client.get(f"/api/v1/people/{person_id}/messages", headers=viewer_headers)
    assert history.json()["items"][0]["content"] == "你好"
