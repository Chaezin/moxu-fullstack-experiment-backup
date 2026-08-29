import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_photo_is_saved_for_current_user(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/register", json={"phone": "13800138041", "password": "StrongPass123"})
    headers = {"Authorization": f"Bearer {response.json()['token']}"}
    uploaded = await client.post("/api/v1/photos", headers=headers, json={"filename": "note.png", "mimeType": "image/png", "dataBase64": "aGVsbG8="})
    assert uploaded.status_code == 201
    photos = await client.get("/api/v1/photos", headers=headers)
    assert photos.json()["items"][0]["filename"] == "note.png"
