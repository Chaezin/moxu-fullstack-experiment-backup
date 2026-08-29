"""仅用于本地开发的可重复演示数据初始化。"""

import os
from hashlib import sha256

from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from app.models import Conversation, GrowthCard, GrowthCardSkill, Message, SkillEvidence, User, UserSkill
from app.security import hash_password


DEMO_USERS = (
    ("13900001001", "林溪", "上海", "喜欢植物照护、记录和社区分享。", "植物照护、摄影记录、社区分享", "观察与整理", "通用能力"),
    ("13900001002", "周禾", "上海", "正在整理四季植物观察册。", "植物观察、摄影、自然教育", "视觉记录", "创意"),
    ("13900001003", "陈屿", "杭州", "喜欢旧物改造，也愿意分享材料经验。", "旧物改造、手作、材料研究", "手作实践", "创意"),
)


def seed_demo_data(session_factory: sessionmaker[Session]) -> dict[str, int]:
    password = os.getenv("SHIGUANG_DEMO_PASSWORD", "ShiguangDemo2026!")
    created = {"users": 0, "conversations": 0, "cards": 0}
    with session_factory() as session:
        for phone, name, city, bio, interests, skill_name, category in DEMO_USERS:
            if session.scalar(select(User).where(User.phone == phone)) is not None:
                continue
            user = User(phone=phone, password_hash=hash_password(password), name=name, city=city, bio=bio, interests=interests)
            session.add(user)
            session.flush()
            conversation = Conversation(user_id=user.id, title="一次真实的成长记录")
            session.add(conversation)
            session.flush()
            message = Message(user_id=user.id, conversation_id=conversation.id, role="user", content=f"我最近完成了一次{skill_name}实践，并把过程整理下来分享给朋友。", sequence_no=1, client_message_id=f"demo:{user.id}")
            session.add(message)
            session.flush()
            skill = UserSkill(user_id=user.id, normalized_name=skill_name.casefold(), name=skill_name, category=category, confidence=0.9)
            session.add(skill)
            session.flush()
            dedupe_key = sha256(f"demo:{user.id}:{skill_name}".encode("utf-8")).hexdigest()
            summary = f"通过具体行动完成了{skill_name}实践，并形成了可以继续使用的方法。"
            evidence = SkillEvidence(user_id=user.id, skill_id=skill.id, message_id=message.id, conversation_id=conversation.id, summary=summary, score=0.9, fingerprint=sha256(f"demo-evidence:{user.id}:{skill_name}".encode("utf-8")).hexdigest())
            card = GrowthCard(user_id=user.id, title=f"我看见了自己的{skill_name}", summary=summary, source="demo_seed", source_message_id=message.id, dedupe_key=dedupe_key)
            session.add_all([evidence, card])
            session.flush()
            session.add(GrowthCardSkill(card_id=card.id, skill_id=skill.id))
            created["users"] += 1
            created["conversations"] += 1
            created["cards"] += 1
        session.commit()
    return created
