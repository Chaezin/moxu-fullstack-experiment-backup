from hashlib import sha256
from typing import Protocol

from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from app.analysis import CARD_THRESHOLD, AnalysisResult
from app.models import (
    AnalysisJob,
    GrowthCard,
    GrowthCardSkill,
    Message,
    SkillEvidence,
    UserSkill,
)


class SkillExtractor(Protocol):
    def analyze(self, content: str) -> AnalysisResult: ...


def process_all_analysis_jobs(
    session_factory: sessionmaker[Session],
    extractor: SkillExtractor,
    max_jobs: int = 1_000,
) -> int:
    processed_count = 0
    while processed_count < max_jobs and process_next_analysis_job(session_factory, extractor):
        processed_count += 1
    return processed_count


def process_next_analysis_job(
    session_factory: sessionmaker[Session],
    extractor: SkillExtractor,
    user_id: str | None = None,
) -> bool:
    with session_factory() as session:
        conditions = [AnalysisJob.status == "pending"]
        if user_id is not None:
            conditions.append(AnalysisJob.user_id == user_id)
        job = session.scalar(
            select(AnalysisJob)
            .where(*conditions)
            .order_by(AnalysisJob.created_at)
        )
        if job is None:
            return False

        message = session.get(Message, job.trigger_message_id)
        if message is None:
            job.status = "failed"
            job.error_summary = "触发消息不存在"
            job.attempts += 1
            session.commit()
            return True

        job_id = job.id
        attempt_number = job.attempts + 1
        job.status = "processing"
        job.attempts = attempt_number
        try:
            result = extractor.analyze(message.content)
            skills = _save_new_evidence(session, job, message, result)
            if skills:
                _create_card(session, job, message, result, skills)
            job.status = "completed"
            job.error_summary = None
            session.commit()
        except Exception as error:
            session.rollback()
            failed_job = session.get(AnalysisJob, job_id)
            if failed_job is not None:
                failed_job.attempts = attempt_number
                failed_job.status = "pending" if attempt_number < 3 else "failed"
                failed_job.error_summary = str(error)[:500]
                session.commit()
        return True


def _save_new_evidence(
    session: Session,
    job: AnalysisJob,
    message: Message,
    result: AnalysisResult,
) -> list[UserSkill]:
    saved_skills: list[UserSkill] = []
    for candidate in result.skills:
        if candidate.score < CARD_THRESHOLD:
            continue
        normalized_name = candidate.name.casefold().strip()
        skill = session.scalar(
            select(UserSkill).where(
                UserSkill.user_id == job.user_id,
                UserSkill.normalized_name == normalized_name,
            )
        )
        if skill is None:
            skill = UserSkill(
                user_id=job.user_id,
                normalized_name=normalized_name,
                name=candidate.name,
                category=candidate.category,
                confidence=candidate.score,
            )
            session.add(skill)
            session.flush()
        else:
            skill.confidence = max(skill.confidence, candidate.score)

        fingerprint = sha256(
            f"{job.user_id}|{normalized_name}|{result.summary}".encode("utf-8")
        ).hexdigest()
        existing = session.scalar(
            select(SkillEvidence).where(
                SkillEvidence.user_id == job.user_id,
                SkillEvidence.fingerprint == fingerprint,
            )
        )
        if existing is None:
            session.add(
                SkillEvidence(
                    user_id=job.user_id,
                    skill_id=skill.id,
                    message_id=message.id,
                    conversation_id=message.conversation_id,
                    summary=result.summary,
                    score=candidate.score,
                    fingerprint=fingerprint,
                )
            )
            saved_skills.append(skill)
    return saved_skills


def _create_card(
    session: Session,
    job: AnalysisJob,
    message: Message,
    result: AnalysisResult,
    skills: list[UserSkill],
) -> None:
    dedupe_key = sha256(f"message:{message.id}".encode("utf-8")).hexdigest()
    existing = session.scalar(
        select(GrowthCard).where(
            GrowthCard.user_id == job.user_id,
            GrowthCard.dedupe_key == dedupe_key,
        )
    )
    if existing is not None:
        return
    skill_names = "、".join(skill.name for skill in skills[:3])
    card = GrowthCard(
        user_id=job.user_id,
        title=f"{skill_names}成长记录",
        summary=result.summary,
        source="ai_auto",
        source_message_id=message.id,
        dedupe_key=dedupe_key,
    )
    session.add(card)
    session.flush()
    for skill in skills:
        session.add(GrowthCardSkill(card_id=card.id, skill_id=skill.id))
