import os
from pathlib import Path

from app.main import create_app
from app.ai import build_ai_from_env


def _load_local_env() -> None:
    """加载本地开发配置，生产环境仍应使用进程环境变量或密钥服务。"""
    env_file = Path(__file__).with_name(".env.local")
    if not env_file.exists():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"\''))


_load_local_env()


database_url = os.getenv("SHIGUANG_DATABASE_URL", "sqlite:///./shiguang.db")
secret_key = os.getenv("SHIGUANG_SECRET_KEY", "")
origins = tuple(
    item.strip()
    for item in os.getenv(
        "SHIGUANG_CORS_ORIGINS",
        "http://127.0.0.1:8765,http://localhost:8765",
    ).split(",")
    if item.strip()
)

ai = build_ai_from_env()

app = create_app(
    database_url=database_url,
    secret_key=secret_key,
    allowed_origins=origins,
    analysis_extractor=ai,
    chat_responder=ai,
    insight_generator=ai,
)

