from collections.abc import Generator

from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


def build_session_factory(database_url: str) -> sessionmaker[Session]:
    connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
    engine = create_engine(database_url, connect_args=connect_args)
    Base.metadata.create_all(engine)
    if database_url.startswith("sqlite"):
        _upgrade_sqlite_schema(engine)
    return sessionmaker(bind=engine, expire_on_commit=False)


def _upgrade_sqlite_schema(engine) -> None:
    user_columns = {column["name"] for column in inspect(engine).get_columns("users")}
    additions = {
        "name": "VARCHAR(80) NOT NULL DEFAULT ''",
        "birthday": "VARCHAR(16) NOT NULL DEFAULT ''",
        "city": "VARCHAR(80) NOT NULL DEFAULT ''",
        "bio": "VARCHAR(500) NOT NULL DEFAULT ''",
        "interests": "VARCHAR(500) NOT NULL DEFAULT ''",
        "public_profile": "BOOLEAN NOT NULL DEFAULT 1",
    }
    missing = [(name, definition) for name, definition in additions.items() if name not in user_columns]
    if not missing:
        pass
    with engine.begin() as connection:
        for name, definition in missing:
            connection.exec_driver_sql(f'ALTER TABLE users ADD COLUMN "{name}" {definition}')
        table_names = set(inspect(engine).get_table_names())
        if "user_skills" in table_names:
            skill_columns = {column["name"] for column in inspect(engine).get_columns("user_skills")}
            if "visibility" not in skill_columns:
                connection.exec_driver_sql(
                    'ALTER TABLE user_skills ADD COLUMN "visibility" VARCHAR(16) NOT NULL DEFAULT \'visible\''
                )


def session_dependency(
    session_factory: sessionmaker[Session],
) -> Generator[Session, None, None]:
    with session_factory() as session:
        yield session
