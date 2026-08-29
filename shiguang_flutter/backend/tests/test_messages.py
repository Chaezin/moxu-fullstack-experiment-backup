import pytest
from httpx import AsyncClient

from tests.test_conversations import register_user


@pytest.mark.anyio
async def test_message_retry_is_idempotent_and_persists_once(client: AsyncClient) -> None:
    token = await register_user(client, "13800138000")
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "持久化测试"},
    )
    message_url = f"/api/v1/conversations/{conversation.json()['id']}/messages"
    payload = {
        "content": "我完成了今天的演讲练习。",
        "clientMessageId": "client-message-001",
    }

    first = await client.post(message_url, headers=headers, json=payload)
    retried = await client.post(message_url, headers=headers, json=payload)
    listed = await client.get(message_url, headers=headers)

    assert first.status_code == 201
    assert first.json()["analysisStatus"] == "pending"
    assert retried.status_code == 201
    assert retried.json()["id"] == first.json()["id"]
    assert len(listed.json()["items"]) == 2
    assert listed.json()["items"][0]["content"] == payload["content"]
    assert [item["role"] for item in listed.json()["items"]] == ["user", "assistant"]


@pytest.mark.anyio
async def test_messages_are_restored_after_user_logs_in_again(client: AsyncClient) -> None:
    phone = "13800138000"
    password = "StrongPass123"
    token = await register_user(client, phone)
    headers = {"Authorization": f"Bearer {token}"}
    conversation = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "重新登录后仍存在"},
    )
    conversation_id = conversation.json()["id"]
    await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"content": "这段话不能消失。", "clientMessageId": "persist-001"},
    )

    logged_in = await client.post(
        "/api/v1/auth/login/password",
        json={"phone": phone, "password": password},
    )
    restored_headers = {"Authorization": f"Bearer {logged_in.json()['token']}"}
    restored = await client.get(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=restored_headers,
    )

    assert restored.status_code == 200
    assert [item["role"] for item in restored.json()["items"]] == ["user", "assistant"]
    assert restored.json()["items"][0]["content"] == "这段话不能消失。"
