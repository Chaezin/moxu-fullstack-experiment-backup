from datetime import datetime, timedelta, timezone
from hashlib import sha256
from secrets import token_urlsafe

import jwt
from pwdlib import PasswordHash


password_hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return password_hasher.verify(password, password_hash)


def create_access_token(user_id: str, secret_key: str) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {"sub": user_id, "type": "access", "iat": now, "exp": now + timedelta(minutes=15)},
        secret_key,
        algorithm="HS256",
    )


def decode_access_token(token: str, secret_key: str) -> str:
    payload = jwt.decode(token, secret_key, algorithms=["HS256"])
    if payload.get("type") != "access" or not payload.get("sub"):
        raise jwt.InvalidTokenError("not an access token")
    return str(payload["sub"])


def create_refresh_token() -> tuple[str, str, datetime]:
    raw_token = token_urlsafe(48)
    expires_at = datetime.now(timezone.utc) + timedelta(days=30)
    return raw_token, hash_refresh_token(raw_token), expires_at


def hash_refresh_token(raw_token: str) -> str:
    return sha256(raw_token.encode("utf-8")).hexdigest()
