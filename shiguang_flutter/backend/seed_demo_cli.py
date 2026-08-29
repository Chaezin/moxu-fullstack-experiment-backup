import os

from app.database import build_session_factory
from app.demo_seed import seed_demo_data


if __name__ == "__main__":
    factory = build_session_factory(os.getenv("SHIGUANG_DATABASE_URL", "sqlite:///./shiguang.db"))
    print(seed_demo_data(factory))
