import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_export_contains_only_current_users_data(client: AsyncClient) -> None:
    registered = await client.post("/api/v1/auth/register", json={"phone": "13800138031", "password": "StrongPass123"})
    headers = {"Authorization": f"Bearer {registered.json()['token']}"}
    json_export = await client.get("/api/v1/export?format=json", headers=headers)
    assert json_export.status_code == 200
    assert json_export.json()["user"]["phone"] == "13800138031"
    txt_export = await client.get("/api/v1/export?format=txt", headers=headers)
    assert txt_export.status_code == 200
    assert "13800138031" in txt_export.text
