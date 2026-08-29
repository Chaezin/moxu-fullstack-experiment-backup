import argparse
import os

from app.analysis import KeywordSkillExtractor
from app.database import build_session_factory
from app.worker import process_all_analysis_jobs


def main() -> None:
    parser = argparse.ArgumentParser(description="运行拾光成长分析补偿任务")
    parser.add_argument("--max-jobs", type=int, default=1_000)
    args = parser.parse_args()
    database_url = os.getenv("SHIGUANG_DATABASE_URL", "sqlite:///./shiguang.db")
    session_factory = build_session_factory(database_url)
    count = process_all_analysis_jobs(session_factory, KeywordSkillExtractor(), args.max_jobs)
    print(f"processed={count}")


if __name__ == "__main__":
    main()

