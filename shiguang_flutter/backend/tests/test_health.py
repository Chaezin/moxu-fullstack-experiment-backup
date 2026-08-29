import pytest
from httpx import ASGITransport, AsyncClient

from app.main import create_app

TEST_SECRET_KEY = "test-secret-key-with-at-least-32-bytes"


@pytest.mark.anyio
async def test_health_check_reports_service_ready() -> None:
    transport = ASGITransport(app=create_app(secret_key=TEST_SECRET_KEY))

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.anyio
async def test_local_preview_origin_is_allowed() -> None:
    transport = ASGITransport(app=create_app(secret_key=TEST_SECRET_KEY))

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/health",
            headers={"Origin": "http://127.0.0.1:8765"},
        )

    assert response.headers["access-control-allow-origin"] == "http://127.0.0.1:8765"


def test_short_secret_key_is_rejected() -> None:
    with pytest.raises(ValueError, match="at least 32 characters"):
        create_app(secret_key="too-short")
