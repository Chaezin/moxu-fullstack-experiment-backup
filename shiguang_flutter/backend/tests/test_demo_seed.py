from sqlalchemy import func, select

from app.database import build_session_factory
from app.demo_seed import seed_demo_data
from app.models import Conversation, GrowthCard, SkillEvidence, User, UserSkill


def test_demo_seed_creates_complete_idempotent_showcase(tmp_path) -> None:
    session_factory = build_session_factory(f"sqlite:///{(tmp_path / 'demo.db').as_posix()}")

    first = seed_demo_data(session_factory)
    second = seed_demo_data(session_factory)

    assert first == {"users": 3, "conversations": 3, "cards": 3}
    assert second == {"users": 0, "conversations": 0, "cards": 0}
    with session_factory() as session:
        assert session.scalar(select(func.count()).select_from(User)) == 3
        assert session.scalar(select(func.count()).select_from(Conversation)) == 3
        assert session.scalar(select(func.count()).select_from(GrowthCard)) == 3
        assert session.scalar(select(func.count()).select_from(UserSkill)) >= 3
        assert session.scalar(select(func.count()).select_from(SkillEvidence)) >= 3
