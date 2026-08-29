"""按用户本地时间执行每日分析补偿。"""

from datetime import datetime, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from app.models import CardSchedule, ScheduledRun
from app.worker import SkillExtractor, process_next_analysis_job


def run_due_schedules(
    session_factory: sessionmaker[Session],
    extractor: SkillExtractor,
    now: datetime | None = None,
) -> int:
    current = now or datetime.now(timezone.utc)
    with session_factory() as session:
        schedules = session.scalars(select(CardSchedule).where(CardSchedule.enabled.is_(True))).all()
        due = []
        for schedule in schedules:
            local_now = current.astimezone(ZoneInfo(schedule.timezone_name))
            local_date = local_now.date().isoformat()
            if local_now.strftime("%H:%M") < schedule.local_time or schedule.last_run_date == local_date:
                continue
            due.append((schedule.id, schedule.user_id, local_date))

    completed = 0
    for schedule_id, user_id, local_date in due:
        processed = 0
        while process_next_analysis_job(session_factory, extractor, user_id=user_id):
            processed += 1
        with session_factory() as session:
            schedule = session.get(CardSchedule, schedule_id)
            if schedule is None or schedule.last_run_date == local_date:
                continue
            session.add(ScheduledRun(schedule_id=schedule.id, user_id=user_id, local_date=local_date, processed_jobs=processed))
            schedule.last_run_date = local_date
            session.commit()
            completed += 1
    return completed
