import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from app.main import create_app


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


@pytest.fixture
def app(tmp_path) -> FastAPI:
    database_url = f"sqlite:///{(tmp_path / 'test.db').as_posix()}"
    return create_app(
        database_url=database_url,
        secret_key="test-secret-key-with-at-least-32-bytes",
        enable_background_analysis=False,
    )


@pytest.fixture
async def client(app: FastAPI):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as test_client:
        yield test_client
