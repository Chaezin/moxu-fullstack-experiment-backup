from datetime import datetime, timezone
import json
from uuid import uuid4
from functools import partial
from hashlib import sha256

from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, Response, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.middleware.cors import CORSMiddleware
import jwt
from sqlalchemy import func, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.analysis import KeywordSkillExtractor
from app.chat import ChatResponder, SupportiveChatResponder
from app.database import build_session_factory, session_dependency
from app.models import (
    AnalysisJob,
    CardSchedule,
    Conversation,
    DirectConversation,
    DirectMessage,
    ExplorationDirection,
    Photo,
    ShareLink,
    GrowthCard,
    GrowthCardRevision,
    Message,
    RefreshToken,
    SkillEvidence,
    SkillRevision,
    User,
    UserSkill,
    utc_now,
)
from app.schemas import (
    ConversationCreate,
    GrowthCardUpdate,
    MessageCreate,
    ProfileUpdate,
    RefreshRequest,
    RegisterRequest,
    VisibilityUpdate,
    PhotoCreate,
    CardScheduleUpdate,
    SkillUpdate,
)
from app.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_password,
    hash_refresh_token,
    verify_password,
)
from app.worker import SkillExtractor, process_next_analysis_job
from app.insights import InsightGenerator, LocalInsightGenerator
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def create_app(
    secret_key: str,
    database_url: str = "sqlite:///./shiguang.db",
    analysis_extractor: SkillExtractor | None = None,
    chat_responder: ChatResponder | None = None,
    enable_background_analysis: bool = True,
    allowed_origins: tuple[str, ...] = (
        "http://127.0.0.1:8765",
        "http://localhost:8765",
    ),
    insight_generator: InsightGenerator | None = None,
) -> FastAPI:
    if len(secret_key) < 32:
        raise ValueError("SHIGUANG_SECRET_KEY must contain at least 32 characters")
    session_factory = build_session_factory(database_url)
    extractor = analysis_extractor or KeywordSkillExtractor()
    responder = chat_responder or SupportiveChatResponder()
    insights = insight_generator or LocalInsightGenerator()
    app = FastAPI(title="我是谁 API", version="1.0.0")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(allowed_origins),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.state.session_factory = session_factory
    get_session = partial(session_dependency, session_factory)
    bearer = HTTPBearer(auto_error=False)

    def get_current_user(
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
        session: Session = Depends(get_session),
    ) -> User:
        if credentials is None:
            raise HTTPException(status_code=401, detail="请先登录")
        try:
            user_id = decode_access_token(credentials.credentials, secret_key)
        except jwt.PyJWTError as error:
            raise HTTPException(status_code=401, detail="登录状态已失效") from error
        user = session.get(User, user_id)
        if user is None:
            raise HTTPException(status_code=401, detail="登录状态已失效")
        return user

    @app.get("/api/v1/health")
    def health_check() -> dict[str, str]:
        return {"status": "ok"}

    @app.post("/api/v1/auth/register", status_code=status.HTTP_201_CREATED)
    def register(payload: RegisterRequest, session: Session = Depends(get_session)) -> dict:
        existing_user = session.scalar(select(User).where(User.phone == payload.phone))
        if existing_user is not None:
            raise HTTPException(status_code=409, detail="该手机号已注册")

        user = User(phone=payload.phone, password_hash=hash_password(payload.password))
        session.add(user)
        try:
            session.flush()
        except IntegrityError as error:
            session.rollback()
            raise HTTPException(status_code=409, detail="该手机号已注册") from error

        refresh_token, refresh_hash, expires_at = create_refresh_token()
        session.add(
            RefreshToken(
                user_id=user.id,
                token_hash=refresh_hash,
                expires_at=expires_at,
            )
        )
        session.commit()

        return {
            "token": create_access_token(user.id, secret_key),
            "refreshToken": refresh_token,
            "user": serialize_user(user),
        }

    @app.post("/api/v1/auth/login/password")
    def password_login(
        payload: RegisterRequest,
        session: Session = Depends(get_session),
    ) -> dict:
        user = session.scalar(select(User).where(User.phone == payload.phone))
        if user is None or not verify_password(payload.password, user.password_hash):
            raise HTTPException(status_code=401, detail="手机号或密码错误")

        refresh_token, refresh_hash, expires_at = create_refresh_token()
        session.add(
            RefreshToken(
                user_id=user.id,
                token_hash=refresh_hash,
                expires_at=expires_at,
            )
        )
        session.commit()
        return {
            "token": create_access_token(user.id, secret_key),
            "refreshToken": refresh_token,
            "user": serialize_user(user),
        }

    @app.get("/api/v1/auth/session")
    def auth_session(user: User = Depends(get_current_user)) -> dict:
        return {"user": serialize_user(user)}

    @app.get("/api/v1/me")
    def get_profile(user: User = Depends(get_current_user)) -> dict:
        return {"profile": serialize_user(user)}

    @app.patch("/api/v1/me")
    def update_profile(
        payload: ProfileUpdate,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(user, field, value.strip() if isinstance(value, str) else value)
        session.commit()
        return {"profile": serialize_user(user)}

    @app.post("/api/v1/me/onboarding")
    def complete_onboarding(
        payload: ProfileUpdate,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(user, field, value.strip() if isinstance(value, str) else value)
        session.commit()
        return {"profile": serialize_user(user)}

    @app.patch("/api/v1/me/visibility")
    def update_visibility(payload: VisibilityUpdate, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        user.public_profile = payload.public
        session.commit()
        return {"profile": serialize_user(user)}

    @app.get("/api/v1/people/recommendations")
    def recommendations(
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        people = session.scalars(
            select(User).where(User.id != user.id, User.name != "", User.public_profile.is_(True)).order_by(User.created_at.desc()).limit(20)
        ).all()
        viewer_interests = set(_interest_list(user.interests))
        ranked = []
        for person in people:
            shared = sorted(viewer_interests.intersection(_interest_list(person.interests)))
            same_city = bool(user.city and person.city and user.city == person.city)
            score = len(shared) * 2 + int(same_city)
            reasons = (["同城"] if same_city else []) + ([f"共同兴趣：{'、'.join(shared)}"] if shared else [])
            item = serialize_public_person(person)
            item["recommendationReason"] = "；".join(reasons) or "对方公开了个人资料，可以先从共同话题开始了解。"
            item["matchScore"] = score
            ranked.append(item)
        ranked.sort(key=lambda item: (-item["matchScore"], item["name"]))
        return {"items": ranked}

    @app.get("/api/v1/people/{person_id}")
    def get_person(person_id: str, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        person = session.scalar(select(User).where(User.id == person_id, User.id != user.id, User.public_profile.is_(True), User.name != ""))
        if person is None:
            raise HTTPException(status_code=404, detail="用户资料不存在或未公开")
        return {"person": serialize_public_person(person)}

    @app.get("/api/v1/people/{person_id}/messages")
    def list_direct_messages(person_id: str, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        person = session.scalar(select(User).where(User.id == person_id, User.public_profile.is_(True)))
        if person is None:
            raise HTTPException(status_code=404, detail="用户不存在或未公开")
        conversation = session.scalar(select(DirectConversation).where(((DirectConversation.user_a_id == user.id) & (DirectConversation.user_b_id == person.id)) | ((DirectConversation.user_a_id == person.id) & (DirectConversation.user_b_id == user.id))))
        messages = session.scalars(select(DirectMessage).where(DirectMessage.conversation_id == conversation.id).order_by(DirectMessage.created_at) if conversation else select(DirectMessage).where(False)).all()
        return {"conversationId": conversation.id if conversation else None, "items": [{"id": item.id, "senderId": item.sender_id, "content": item.content, "createdAt": item.created_at.isoformat()} for item in messages]}

    @app.post("/api/v1/people/{person_id}/messages")
    def send_direct_message(person_id: str, payload: MessageCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        person = session.scalar(select(User).where(User.id == person_id, User.public_profile.is_(True)))
        if person is None:
            raise HTTPException(status_code=404, detail="用户不存在或未公开")
        conversation = session.scalar(select(DirectConversation).where(((DirectConversation.user_a_id == user.id) & (DirectConversation.user_b_id == person.id)) | ((DirectConversation.user_a_id == person.id) & (DirectConversation.user_b_id == user.id))))
        if conversation is None:
            conversation = DirectConversation(user_a_id=user.id, user_b_id=person.id)
            session.add(conversation); session.flush()
        message = DirectMessage(conversation_id=conversation.id, sender_id=user.id, content=payload.content)
        session.add(message); session.commit(); session.refresh(message)
        return {"conversationId": conversation.id, "message": {"id": message.id, "senderId": message.sender_id, "content": message.content, "createdAt": message.created_at.isoformat()}}

    @app.post("/api/v1/auth/refresh")
    def refresh_access_token(
        payload: RefreshRequest,
        session: Session = Depends(get_session),
    ) -> dict:
        stored_token = session.scalar(
            select(RefreshToken).where(
                RefreshToken.token_hash == hash_refresh_token(payload.refresh_token)
            )
        )
        if stored_token is None:
            raise HTTPException(status_code=401, detail="刷新令牌无效")

        expires_at = stored_token.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at <= datetime.now(timezone.utc):
            session.delete(stored_token)
            session.commit()
            raise HTTPException(status_code=401, detail="刷新令牌已过期")

        user = session.get(User, stored_token.user_id)
        if user is None:
            session.delete(stored_token)
            session.commit()
            raise HTTPException(status_code=401, detail="刷新令牌无效")

        session.delete(stored_token)
        new_refresh, new_hash, new_expires_at = create_refresh_token()
        session.add(
            RefreshToken(
                user_id=user.id,
                token_hash=new_hash,
                expires_at=new_expires_at,
            )
        )
        session.commit()
        return {
            "token": create_access_token(user.id, secret_key),
            "refreshToken": new_refresh,
            "user": serialize_user(user),
        }

    @app.post("/api/v1/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
    def logout(
        payload: RefreshRequest,
        session: Session = Depends(get_session),
    ) -> Response:
        stored_token = session.scalar(
            select(RefreshToken).where(
                RefreshToken.token_hash == hash_refresh_token(payload.refresh_token)
            )
        )
        if stored_token is not None:
            session.delete(stored_token)
            session.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    @app.post("/api/v1/conversations", status_code=status.HTTP_201_CREATED)
    def create_conversation(
        payload: ConversationCreate,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        conversation = Conversation(user_id=user.id, title=payload.title.strip())
        session.add(conversation)
        session.commit()
        return {
            "id": conversation.id,
            "title": conversation.title,
            "createdAt": conversation.created_at.isoformat(),
            "updatedAt": conversation.updated_at.isoformat(),
        }

    @app.get("/api/v1/conversations")
    def list_conversations(
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        conversations = session.scalars(
            select(Conversation)
            .where(
                Conversation.user_id == user.id,
                Conversation.deleted_at.is_(None),
            )
            .order_by(Conversation.updated_at.desc())
        ).all()
        return {
            "items": [
                {
                    "id": item.id,
                    "title": item.title,
                    "createdAt": item.created_at.isoformat(),
                    "updatedAt": item.updated_at.isoformat(),
                }
                for item in conversations
            ]
        }

    @app.get("/api/v1/conversations/{conversation_id}")
    def get_conversation(
        conversation_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        conversation = session.scalar(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user.id,
                Conversation.deleted_at.is_(None),
            )
        )
        if conversation is None:
            raise HTTPException(status_code=404, detail="对话不存在")
        return {
            "id": conversation.id,
            "title": conversation.title,
            "createdAt": conversation.created_at.isoformat(),
            "updatedAt": conversation.updated_at.isoformat(),
        }

    @app.delete(
        "/api/v1/conversations/{conversation_id}",
        status_code=status.HTTP_204_NO_CONTENT,
    )
    def delete_conversation(
        conversation_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> Response:
        conversation = session.scalar(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user.id,
                Conversation.deleted_at.is_(None),
            )
        )
        if conversation is None:
            raise HTTPException(status_code=404, detail="对话不存在")
        conversation.deleted_at = utc_now()
        message_ids = select(Message.id).where(
            Message.conversation_id == conversation_id,
            Message.user_id == user.id,
        )
        session.execute(
            update(GrowthCard)
            .where(
                GrowthCard.user_id == user.id,
                GrowthCard.source_message_id.in_(message_ids),
            )
            .values(source_message_id=None)
        )
        session.execute(
            update(SkillEvidence)
            .where(
                SkillEvidence.user_id == user.id,
                SkillEvidence.conversation_id == conversation_id,
            )
            .values(message_id=None, conversation_id=None)
        )
        session.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    @app.post(
        "/api/v1/conversations/{conversation_id}/messages",
        status_code=status.HTTP_201_CREATED,
    )
    def create_message(
        conversation_id: str,
        payload: MessageCreate,
        background_tasks: BackgroundTasks,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        conversation = session.scalar(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user.id,
                Conversation.deleted_at.is_(None),
            )
        )
        if conversation is None:
            raise HTTPException(status_code=404, detail="对话不存在")

        existing = session.scalar(
            select(Message).where(
                Message.user_id == user.id,
                Message.client_message_id == payload.client_message_id,
            )
        )
        if existing is not None:
            if existing.conversation_id != conversation_id or existing.content != payload.content:
                raise HTTPException(status_code=409, detail="消息幂等标识已被使用")
            job = session.scalar(
                select(AnalysisJob).where(AnalysisJob.trigger_message_id == existing.id)
            )
            result = serialize_message(existing, job.status if job else None)
            assistant = session.scalar(
                select(Message).where(
                    Message.conversation_id == conversation_id,
                    Message.sequence_no == existing.sequence_no + 1,
                    Message.role == "assistant",
                )
            )
            if assistant is not None:
                result["assistant"] = serialize_message(assistant)
            return result

        last_sequence = session.scalar(
            select(func.max(Message.sequence_no)).where(
                Message.conversation_id == conversation_id
            )
        )
        message = Message(
            user_id=user.id,
            conversation_id=conversation_id,
            content=payload.content.strip(),
            sequence_no=(last_sequence or 0) + 1,
            client_message_id=payload.client_message_id,
        )
        assistant = Message(
            user_id=user.id,
            conversation_id=conversation_id,
            role="assistant",
            content=responder.respond(payload.content),
            sequence_no=(last_sequence or 0) + 2,
            client_message_id=(
                "assistant:"
                + sha256(payload.client_message_id.encode("utf-8")).hexdigest()
            ),
        )
        conversation.updated_at = utc_now()
        session.add_all([message, assistant])
        session.flush()
        job = AnalysisJob(
            user_id=user.id,
            conversation_id=conversation_id,
            trigger_message_id=message.id,
        )
        session.add(job)
        session.commit()
        if enable_background_analysis:
            background_tasks.add_task(
                process_next_analysis_job,
                session_factory,
                extractor,
            )
        result = serialize_message(message, job.status)
        result["assistant"] = serialize_message(assistant)
        return result

    @app.get("/api/v1/conversations/{conversation_id}/messages")
    def list_messages(
        conversation_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        conversation = session.scalar(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user.id,
                Conversation.deleted_at.is_(None),
            )
        )
        if conversation is None:
            raise HTTPException(status_code=404, detail="对话不存在")
        messages = session.scalars(
            select(Message)
            .where(
                Message.conversation_id == conversation_id,
                Message.user_id == user.id,
            )
            .order_by(Message.sequence_no)
        ).all()
        return {"items": [serialize_message(message) for message in messages]}

    def serialize_schedule(schedule: CardSchedule | None) -> dict:
        return {
            "enabled": schedule.enabled if schedule else False,
            "localTime": schedule.local_time if schedule else "21:30",
            "timezone": schedule.timezone_name if schedule else "Asia/Shanghai",
            "lastRunDate": schedule.last_run_date if schedule else None,
        }

    @app.get("/api/v1/settings/card-schedule")
    def get_card_schedule(
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        schedule = session.scalar(select(CardSchedule).where(CardSchedule.user_id == user.id))
        return {"schedule": serialize_schedule(schedule)}

    @app.put("/api/v1/settings/card-schedule")
    def update_card_schedule(
        payload: CardScheduleUpdate,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        try:
            ZoneInfo(payload.timezone)
        except ZoneInfoNotFoundError as error:
            raise HTTPException(status_code=422, detail="无效的时区") from error
        schedule = session.scalar(select(CardSchedule).where(CardSchedule.user_id == user.id))
        if schedule is None:
            schedule = CardSchedule(user_id=user.id)
            session.add(schedule)
        schedule.enabled = payload.enabled
        schedule.local_time = payload.local_time
        schedule.timezone_name = payload.timezone
        session.commit()
        return {"schedule": serialize_schedule(schedule)}

    @app.get("/api/v1/skills")
    def list_skills(
        includeHidden: bool = False,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        conditions = [UserSkill.user_id == user.id]
        if not includeHidden:
            conditions.append(UserSkill.visibility == "visible")
        skills = session.scalars(
            select(UserSkill)
            .where(*conditions)
            .order_by(UserSkill.confidence.desc(), UserSkill.name)
        ).all()
        return {
            "items": [
                {
                    "id": skill.id,
                    "name": skill.name,
                    "category": skill.category,
                    "confidence": skill.confidence,
                    "visibility": skill.visibility,
                }
                for skill in skills
            ]
        }

    @app.get("/api/v1/cards")
    def list_cards(
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        cards = session.scalars(
            select(GrowthCard)
            .where(
                GrowthCard.user_id == user.id,
                GrowthCard.status == "active",
            )
            .order_by(GrowthCard.created_at.desc())
        ).all()
        return {
            "items": [
                {
                    "id": card.id,
                    "title": card.title,
                    "summary": card.summary,
                    "source": card.source,
                    "sourceAvailable": card.source_message_id is not None,
                    "createdAt": card.created_at.isoformat(),
                }
                for card in cards
            ]
        }

    @app.patch("/api/v1/cards/{card_id}")
    def update_card(
        card_id: str,
        payload: GrowthCardUpdate,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        card = session.scalar(
            select(GrowthCard).where(
                GrowthCard.id == card_id,
                GrowthCard.user_id == user.id,
                GrowthCard.status == "active",
            )
        )
        if card is None:
            raise HTTPException(status_code=404, detail="成长卡片不存在")
        if payload.title is not None:
            card.title = payload.title.strip()
        if payload.summary is not None:
            card.summary = payload.summary.strip()
        session.commit()
        return {
            "id": card.id,
            "title": card.title,
            "summary": card.summary,
            "source": card.source,
            "sourceAvailable": card.source_message_id is not None,
            "createdAt": card.created_at.isoformat(),
        }

    @app.patch("/api/v1/skills/{skill_id}")
    def update_skill(
        skill_id: str,
        payload: SkillUpdate,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        skill = session.scalar(select(UserSkill).where(UserSkill.id == skill_id, UserSkill.user_id == user.id))
        if skill is None:
            raise HTTPException(status_code=404, detail="能力不存在")
        before = {"name": skill.name, "category": skill.category, "visibility": skill.visibility}
        if payload.name is not None:
            skill.name = payload.name.strip()
            skill.normalized_name = skill.name.casefold()
        if payload.category is not None:
            skill.category = payload.category.strip()
        if payload.visibility is not None:
            skill.visibility = payload.visibility
        after = {"name": skill.name, "category": skill.category, "visibility": skill.visibility}
        session.add(SkillRevision(user_id=user.id, skill_id=skill.id, action=payload.feedback, before_json=json.dumps(before, ensure_ascii=False), after_json=json.dumps(after, ensure_ascii=False)))
        session.commit()
        return {"id": skill.id, **after, "confidence": skill.confidence}

    @app.get("/api/v1/skills/{skill_id}")
    def get_skill_detail(
        skill_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        skill = session.scalar(select(UserSkill).where(UserSkill.id == skill_id, UserSkill.user_id == user.id))
        if skill is None:
            raise HTTPException(status_code=404, detail="能力不存在")
        evidence_rows = session.scalars(select(SkillEvidence).where(SkillEvidence.skill_id == skill.id, SkillEvidence.user_id == user.id).order_by(SkillEvidence.created_at.desc())).all()
        evidence = [item.summary for item in evidence_rows]
        detail = insights.describe_skill(skill.name, skill.category, evidence)
        return {"skill": {"id": skill.id, "name": skill.name, "category": skill.category, "confidence": skill.confidence, "visibility": skill.visibility, **detail, "evidence": [{"id": item.id, "summary": item.summary, "score": item.score, "createdAt": item.created_at.isoformat()} for item in evidence_rows]}}

    @app.get("/api/v1/directions")
    def list_directions(user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        items = session.scalars(select(ExplorationDirection).where(ExplorationDirection.user_id == user.id).order_by(ExplorationDirection.created_at, ExplorationDirection.id)).all()
        return {"items": [{"id": item.id, "title": item.title, "summary": item.summary, "reason": item.reason} for item in items]}

    @app.post("/api/v1/directions/refresh")
    def refresh_directions(user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        skills = session.scalars(select(UserSkill).where(UserSkill.user_id == user.id, UserSkill.visibility == "visible").order_by(UserSkill.confidence.desc())).all()
        interests = [item.strip() for item in user.interests.replace("，", "、").split("、") if item.strip()]
        suggestions = insights.suggest_directions([item.name for item in skills], interests)
        existing = session.scalars(select(ExplorationDirection).where(ExplorationDirection.user_id == user.id)).all()
        for item in existing:
            session.delete(item)
        session.flush()
        for suggestion in suggestions[:4]:
            session.add(ExplorationDirection(user_id=user.id, title=suggestion.title, summary=suggestion.summary, reason=suggestion.reason))
        session.commit()
        return list_directions(user, session)

    @app.get("/api/v1/skills/{skill_id}/history")
    def skill_history(
        skill_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        skill = session.scalar(select(UserSkill).where(UserSkill.id == skill_id, UserSkill.user_id == user.id))
        if skill is None:
            raise HTTPException(status_code=404, detail="能力不存在")
        revisions = session.scalars(select(SkillRevision).where(SkillRevision.skill_id == skill.id, SkillRevision.user_id == user.id).order_by(SkillRevision.created_at.desc(), SkillRevision.id.desc())).all()
        return {"items": [{"id": revision.id, "action": revision.action, "before": json.loads(revision.before_json), "after": json.loads(revision.after_json), "createdAt": revision.created_at.isoformat()} for revision in revisions]}

    @app.get("/api/v1/cards/{card_id}")
    def get_card_detail(
        card_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        card = session.scalar(select(GrowthCard).where(GrowthCard.id == card_id, GrowthCard.user_id == user.id, GrowthCard.status == "active"))
        if card is None:
            raise HTTPException(status_code=404, detail="成长卡片不存在")
        evidence_rows = session.execute(select(SkillEvidence, UserSkill).join(UserSkill, UserSkill.id == SkillEvidence.skill_id).where(SkillEvidence.user_id == user.id, SkillEvidence.message_id == card.source_message_id)).all() if card.source_message_id else []
        return {**serialize_card(card), "evidence": [{"skill": skill.name, "category": skill.category, "summary": evidence.summary, "score": evidence.score} for evidence, skill in evidence_rows]}

    def change_card_status(card_id: str, target: str, action: str, user: User, session: Session) -> dict:
        allowed_source = "active" if target == "undone" else "undone"
        card = session.scalar(select(GrowthCard).where(GrowthCard.id == card_id, GrowthCard.user_id == user.id, GrowthCard.status == allowed_source))
        if card is None:
            raise HTTPException(status_code=404, detail="成长卡片不存在或状态不允许")
        card.status = target
        session.add(GrowthCardRevision(user_id=user.id, card_id=card.id, action=action))
        session.commit()
        return {**serialize_card(card), "status": card.status}

    @app.post("/api/v1/cards/{card_id}/undo")
    def undo_card(card_id: str, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        return change_card_status(card_id, "undone", "undone", user, session)

    @app.post("/api/v1/cards/{card_id}/restore")
    def restore_card(card_id: str, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        return change_card_status(card_id, "active", "restored", user, session)

    @app.get("/api/v1/cards/{card_id}/history")
    def card_history(card_id: str, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        card = session.scalar(select(GrowthCard).where(GrowthCard.id == card_id, GrowthCard.user_id == user.id))
        if card is None:
            raise HTTPException(status_code=404, detail="成长卡片不存在")
        revisions = session.scalars(select(GrowthCardRevision).where(GrowthCardRevision.card_id == card.id, GrowthCardRevision.user_id == user.id).order_by(GrowthCardRevision.created_at.desc(), GrowthCardRevision.id.desc())).all()
        return {"items": [{"id": item.id, "action": item.action, "createdAt": item.created_at.isoformat()} for item in revisions]}

    @app.get("/api/v1/reports/monthly")
    def monthly_report(
        month: str | None = None,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> dict:
        selected = month or datetime.now(timezone.utc).strftime("%Y-%m")
        cards = session.scalars(select(GrowthCard).where(GrowthCard.user_id == user.id, GrowthCard.status == "active")).all()
        month_cards = [card for card in cards if card.created_at.strftime("%Y-%m") == selected]
        skills = session.scalars(select(UserSkill).where(UserSkill.user_id == user.id).order_by(UserSkill.confidence.desc())).all()
        return {"report": {"month": selected, "title": f"{selected} 成长回顾", "summary": f"本月形成了 {len(month_cards)} 张成长卡片，持续记录正在变成可复用的方法。" if month_cards else "本月还没有足够的成长记录。", "keywords": [skill.name for skill in skills[:4]], "cardCount": len(month_cards)}}

    @app.delete("/api/v1/cards/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
    def delete_card(
        card_id: str,
        user: User = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> Response:
        card = session.scalar(
            select(GrowthCard).where(
                GrowthCard.id == card_id,
                GrowthCard.user_id == user.id,
                GrowthCard.status == "active",
            )
        )
        if card is None:
            raise HTTPException(status_code=404, detail="成长卡片不存在")
        card.status = "deleted"
        session.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    @app.get("/api/v1/export")
    def export_archive(format: str = "json", user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> Response:
        conversations = session.scalars(select(Conversation).where(Conversation.user_id == user.id, Conversation.deleted_at.is_(None)).order_by(Conversation.created_at)).all()
        payload = {"user": serialize_user(user), "conversations": []}
        for conversation in conversations:
            messages = session.scalars(select(Message).where(Message.conversation_id == conversation.id).order_by(Message.sequence_no)).all()
            payload["conversations"].append({"id": conversation.id, "title": conversation.title, "messages": [serialize_message(message) for message in messages]})
        if format.lower() == "txt":
            lines = [f"我是谁 · 个人成长档案：{user.name or user.phone}"]
            for item in payload["conversations"]:
                lines.append(f"\n## {item['title']}")
                lines.extend(f"{message['role']}: {message['content']}" for message in item["messages"])
            return Response("\n".join(lines), media_type="text/plain", headers={"Content-Disposition": "attachment; filename=shiguang-archive.txt"})
        return Response(json.dumps(payload, ensure_ascii=False), media_type="application/json", headers={"Content-Disposition": "attachment; filename=shiguang-archive.json"})

    @app.post("/api/v1/photos", status_code=status.HTTP_201_CREATED)
    def upload_photo(payload: PhotoCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        photo = Photo(user_id=user.id, filename=payload.filename, mime_type=payload.mime_type, data_base64=payload.data_base64)
        session.add(photo); session.commit(); session.refresh(photo)
        return {"id": photo.id, "filename": photo.filename, "mimeType": photo.mime_type, "createdAt": photo.created_at.isoformat()}

    @app.get("/api/v1/photos")
    def list_photos(user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        photos = session.scalars(select(Photo).where(Photo.user_id == user.id).order_by(Photo.created_at.desc())).all()
        return {"items": [{"id": photo.id, "filename": photo.filename, "mimeType": photo.mime_type, "createdAt": photo.created_at.isoformat()} for photo in photos]}

    @app.post("/api/v1/me/share")
    def create_share_link(user: User = Depends(get_current_user), session: Session = Depends(get_session)) -> dict:
        token = sha256(f"{user.id}:{uuid4()}".encode()).hexdigest()[:40]
        session.add(ShareLink(token=token, user_id=user.id)); session.commit()
        return {"token": token, "url": f"/?share={token}"}

    @app.get("/api/v1/shared/{token}")
    def read_shared_profile(token: str, session: Session = Depends(get_session)) -> dict:
        link = session.scalar(select(ShareLink).where(ShareLink.token == token, ShareLink.revoked.is_(False)))
        if link is None:
            raise HTTPException(status_code=404, detail="分享链接不存在或已失效")
        user = session.get(User, link.user_id)
        if user is None or not user.public_profile:
            raise HTTPException(status_code=404, detail="个人资料未公开")
        return {"person": serialize_public_person(user)}

    return app


def serialize_public_person(person: User) -> dict:
    return {"id": person.id, "name": person.name, "city": person.city, "bio": person.bio, "publicInterests": _interest_list(person.interests), "online": False}


def _interest_list(value: str) -> list[str]:
    return [item.strip() for item in value.replace("，", ",").replace("、", ",").split(",") if item.strip()]


def serialize_message(message: Message, analysis_status: str | None = None) -> dict:
    result = {
        "id": message.id,
        "conversationId": message.conversation_id,
        "role": message.role,
        "content": message.content,
        "sequence": message.sequence_no,
        "clientMessageId": message.client_message_id,
        "createdAt": message.created_at.isoformat(),
    }
    if analysis_status is not None:
        result["analysisStatus"] = analysis_status
    return result


def serialize_card(card: GrowthCard) -> dict:
    return {
        "id": card.id,
        "title": card.title,
        "summary": card.summary,
        "source": card.source,
        "sourceAvailable": card.source_message_id is not None,
        "createdAt": card.created_at.isoformat(),
    }


def serialize_user(user: User) -> dict:
    interests = [item.strip() for item in user.interests.split("、") if item.strip()]
    return {
        "id": user.id,
        "phone": user.phone,
        "name": user.name,
        "birthday": user.birthday,
        "city": user.city,
        "bio": user.bio,
        "interests": interests,
        "publicProfile": user.public_profile,
        "onboardingComplete": bool(user.name or user.bio or user.city),
    }
