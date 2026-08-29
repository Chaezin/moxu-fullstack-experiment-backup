from pydantic import BaseModel, Field
from typing import Literal


class RegisterRequest(BaseModel):
    phone: str = Field(min_length=5, max_length=32)
    password: str = Field(min_length=8, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(alias="refreshToken", min_length=32, max_length=256)


class ConversationCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=20_000)
    client_message_id: str = Field(alias="clientMessageId", min_length=1, max_length=128)


class GrowthCardUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=160)
    summary: str | None = Field(default=None, min_length=1, max_length=4_000)


class SkillUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    category: str | None = Field(default=None, min_length=1, max_length=64)
    visibility: Literal["visible", "hidden"] | None = None
    feedback: Literal["confirmed", "corrected", "hidden", "restored"]


class CardScheduleUpdate(BaseModel):
    enabled: bool
    local_time: str = Field(alias="localTime", pattern=r"^(?:[01]\d|2[0-3]):[0-5]\d$")
    timezone: str = Field(min_length=1, max_length=64)


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=80)
    birthday: str | None = Field(default=None, max_length=16)
    city: str | None = Field(default=None, max_length=80)
    bio: str | None = Field(default=None, max_length=500)
    interests: str | None = Field(default=None, max_length=500)


class VisibilityUpdate(BaseModel):
    public: bool


class PhotoCreate(BaseModel):
    filename: str = Field(min_length=1, max_length=255)
    mime_type: str = Field(alias="mimeType", min_length=1, max_length=100)
    data_base64: str = Field(alias="dataBase64", min_length=1, max_length=8_000_000)
