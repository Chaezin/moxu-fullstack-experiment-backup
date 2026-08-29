import pytest
from httpx import AsyncClient


async def register_user(client: AsyncClient, phone: str) -> str:
    response = await client.post(
        "/api/v1/auth/register",
        json={"phone": phone, "password": "StrongPass123"},
    )
    return response.json()["token"]


@pytest.mark.anyio
async def test_user_can_create_and_list_own_conversations(client: AsyncClient) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}

    created = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "第一次成长对话"},
    )
    listed = await client.get("/api/v1/conversations", headers=headers)

    assert created.status_code == 201
    assert created.json()["title"] == "第一次成长对话"
    assert listed.status_code == 200
    assert [item["id"] for item in listed.json()["items"]] == [created.json()["id"]]


@pytest.mark.anyio
async def test_user_can_load_own_conversation(client: AsyncClient) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    created = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "只属于我的对话"},
    )

    response = await client.get(
        f"/api/v1/conversations/{created.json()['id']}",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["id"] == created.json()["id"]


@pytest.mark.anyio
async def test_user_cannot_read_another_users_conversation(client: AsyncClient) -> None:
    owner_token = await register_user(client, "13800138000")
    stranger_token = await register_user(client, "13900139000")
    created = await client.post(
        "/api/v1/conversations",
        headers={"Authorization": f"Bearer {owner_token}"},
        json={"title": "私密对话"},
    )

    response = await client.get(
        f"/api/v1/conversations/{created.json()['id']}",
        headers={"Authorization": f"Bearer {stranger_token}"},
    )

    assert response.status_code == 404


@pytest.mark.anyio
async def test_deleted_conversation_is_hidden_from_history(client: AsyncClient) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    created = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "准备删除的对话"},
    )
    conversation_id = created.json()["id"]

    deleted = await client.delete(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    loaded = await client.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    listed = await client.get("/api/v1/conversations", headers=headers)

    assert deleted.status_code == 204
    assert loaded.status_code == 404
    assert listed.json()["items"] == []
