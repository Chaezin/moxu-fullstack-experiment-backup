import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_share_link_contains_only_public_profile(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/register", json={"phone": "13800138051", "password": "StrongPass123"})
    headers = {"Authorization": f"Bearer {response.json()['token']}"}
    await client.patch("/api/v1/me", headers=headers, json={"name": "分享用户", "city": "上海", "interests": "摄影"})
    shared = await client.post("/api/v1/me/share", headers=headers)
    assert shared.status_code == 200
    assert shared.json()["url"] == f"/?share={shared.json()['token']}"
    public = await client.get(f"/api/v1/shared/{shared.json()['token']}")
    assert public.status_code == 200
    assert public.json()["person"]["name"] == "分享用户"
    assert "phone" not in public.json()["person"]
