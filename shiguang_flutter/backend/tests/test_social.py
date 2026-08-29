import pytest
from httpx import AsyncClient


async def register(client: AsyncClient, phone: str) -> str:
    response = await client.post(
        "/api/v1/auth/register", json={"phone": phone, "password": "StrongPass123"}
    )
    return response.json()["token"]


@pytest.mark.anyio
async def test_recommendations_are_loaded_from_other_real_users(client: AsyncClient) -> None:
    first = await register(client, "13800138001")
    second = await register(client, "13800138002")
    first_headers = {"Authorization": f"Bearer {first}"}
    second_headers = {"Authorization": f"Bearer {second}"}
    await client.patch(
        "/api/v1/me", headers=first_headers,
        json={"name": "当前用户", "city": "杭州", "interests": "写作,摄影"},
    )
    await client.patch(
        "/api/v1/me", headers=second_headers,
        json={"name": "真实用户", "city": "杭州", "bio": "喜欢整理经验", "interests": "写作,整理"},
    )
    result = await client.get("/api/v1/people/recommendations", headers=first_headers)
    assert result.status_code == 200
    assert result.json()["items"][0]["name"] == "真实用户"
    assert result.json()["items"][0]["publicInterests"] == ["写作", "整理"]
    assert "同城" in result.json()["items"][0]["recommendationReason"]
    assert "写作" in result.json()["items"][0]["recommendationReason"]
