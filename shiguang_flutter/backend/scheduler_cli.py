"""执行一次所有到期用户的每日成长整理。"""

import os

from app.ai import build_ai_from_env
from app.analysis import KeywordSkillExtractor
from app.database import build_session_factory
from app.scheduler import run_due_schedules
from run import _load_local_env


def main() -> None:
    _load_local_env()
    session_factory = build_session_factory(
        os.getenv("SHIGUANG_DATABASE_URL", "sqlite:///./shiguang.db")
    )
    extractor = build_ai_from_env() or KeywordSkillExtractor()
    count = run_due_schedules(session_factory, extractor)
    print(f"已完成 {count} 个用户的到期整理")


if __name__ == "__main__":
    main()
