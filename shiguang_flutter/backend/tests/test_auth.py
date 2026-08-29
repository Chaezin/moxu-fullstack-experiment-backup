import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_register_creates_account_and_returns_tokens(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800138000", "password": "StrongPass123"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["token"]
    assert body["refreshToken"]
    assert body["user"]["phone"] == "13800138000"
    assert "password" not in body["user"]


@pytest.mark.anyio
async def test_register_rejects_duplicate_phone(client: AsyncClient) -> None:
    payload = {"phone": "13800138000", "password": "StrongPass123"}
    first = await client.post("/api/v1/auth/register", json=payload)

    duplicate = await client.post("/api/v1/auth/register", json=payload)

    assert first.status_code == 201
    assert duplicate.status_code == 409
    assert duplicate.json()["detail"] == "该手机号已注册"


@pytest.mark.anyio
async def test_password_login_returns_new_tokens(client: AsyncClient) -> None:
    payload = {"phone": "13800138000", "password": "StrongPass123"}
    await client.post("/api/v1/auth/register", json=payload)

    response = await client.post("/api/v1/auth/login/password", json=payload)

    assert response.status_code == 200
    body = response.json()
    assert body["token"]
    assert body["refreshToken"]
    assert body["user"]["phone"] == payload["phone"]


@pytest.mark.anyio
async def test_session_returns_the_authenticated_user(client: AsyncClient) -> None:
    registered = await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800138000", "password": "StrongPass123"},
    )
    token = registered.json()["token"]

    response = await client.get(
        "/api/v1/auth/session",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()["user"]["phone"] == "13800138000"


@pytest.mark.anyio
async def test_refresh_rotates_token_and_rejects_reuse(client: AsyncClient) -> None:
    registered = await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800138000", "password": "StrongPass123"},
    )
    old_refresh_token = registered.json()["refreshToken"]

    refreshed = await client.post(
        "/api/v1/auth/refresh",
        json={"refreshToken": old_refresh_token},
    )
    reused = await client.post(
        "/api/v1/auth/refresh",
        json={"refreshToken": old_refresh_token},
    )

    assert refreshed.status_code == 200
    assert refreshed.json()["token"]
    assert refreshed.json()["refreshToken"] != old_refresh_token
    assert reused.status_code == 401


@pytest.mark.anyio
async def test_logout_revokes_refresh_token(client: AsyncClient) -> None:
    registered = await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800138000", "password": "StrongPass123"},
    )
    refresh_token = registered.json()["refreshToken"]

    logout = await client.post(
        "/api/v1/auth/logout",
        json={"refreshToken": refresh_token},
    )
    refreshed = await client.post(
        "/api/v1/auth/refresh",
        json={"refreshToken": refresh_token},
    )

    assert logout.status_code == 204
    assert refreshed.status_code == 401
