"""OpenAI-compatible AI adapter with strict parsing and injectable transport."""

import json
import os
from typing import Any, Callable

import httpx

from app.analysis import AnalysisResult, SkillCandidate
from app.analysis import KeywordSkillExtractor
from app.chat import SupportiveChatResponder
from app.insights import DirectionSuggestion, LocalInsightGenerator


Request = Callable[[str, dict[str, str], dict[str, Any], float], dict[str, Any]]


class OpenAICompatibleAI:
    def __init__(
        self,
        base_url: str,
        api_key: str,
        model: str,
        *,
        timeout: float = 30.0,
        request: Request | None = None,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.model = model
        self.timeout = timeout
        self._request = request or self._http_request

    def _http_request(self, url: str, headers: dict[str, str], payload: dict[str, Any], timeout: float) -> dict[str, Any]:
        response = httpx.post(url, headers=headers, json=payload, timeout=timeout)
        response.raise_for_status()
        return response.json()

    def _complete(self, messages: list[dict[str, str]], *, json_mode: bool = False) -> str:
        payload: dict[str, Any] = {"model": self.model, "messages": messages, "temperature": 0.2}
        if json_mode:
            payload["response_format"] = {"type": "json_object"}
        data = self._request(
            f"{self.base_url}/chat/completions",
            {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"},
            payload,
            self.timeout,
        )
        try:
            return str(data["choices"][0]["message"]["content"]).strip()
        except (KeyError, IndexError, TypeError) as error:
            raise ValueError("AI 返回缺少 choices.message.content") from error

    def respond(self, content: str) -> str:
        return self._complete([
            {"role": "system", "content": "你是拾光的温和成长陪伴者。用简洁中文回应，具体、真诚，不编造事实。"},
            {"role": "user", "content": content},
        ])

    def analyze(self, content: str) -> AnalysisResult:
        raw = self._complete([
            {"role": "system", "content": (
                "分析用户叙述中的可验证技能。只返回 JSON："
                '{"summary":"不超过240字","skills":[{"name":"技能名","category":"技术/通用能力/创意/其他","score":0.0}]}'
                "。score 是 0 到 1 的置信度；没有明确技能时返回空数组。"
            )},
            {"role": "user", "content": content},
        ], json_mode=True)
        try:
            parsed = json.loads(raw)
            summary = str(parsed["summary"]).strip()[:240]
            skills = tuple(
                SkillCandidate(
                    name=str(item["name"]).strip(),
                    category=str(item.get("category", "其他")).strip() or "其他",
                    score=max(0.0, min(1.0, float(item["score"]))),
                )
                for item in parsed["skills"]
                if str(item.get("name", "")).strip()
            )
        except (json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
            raise ValueError("AI 分析结果不是有效 JSON") from error
        return AnalysisResult(summary=summary, skills=skills)

    def describe_skill(self, name: str, category: str, evidence: list[str]) -> dict:
        raw = self._complete([
            {"role": "system", "content": "根据真实证据生成能力说明。只返回 JSON，字段为 summary、typicalBehaviors、suitableScenarios、boundaries、evidenceSummary；后三个说明字段使用字符串数组，不得编造证据。"},
            {"role": "user", "content": json.dumps({"name": name, "category": category, "evidence": evidence}, ensure_ascii=False)},
        ], json_mode=True)
        try:
            parsed = json.loads(raw)
            return {
                "summary": str(parsed["summary"])[:500],
                "typicalBehaviors": [str(item)[:200] for item in parsed["typicalBehaviors"]][:5],
                "suitableScenarios": [str(item)[:200] for item in parsed["suitableScenarios"]][:5],
                "boundaries": [str(item)[:200] for item in parsed["boundaries"]][:5],
                "evidenceSummary": str(parsed["evidenceSummary"])[:500],
            }
        except (json.JSONDecodeError, KeyError, TypeError) as error:
            raise ValueError("AI 能力说明不是有效 JSON") from error

    def suggest_directions(self, skills: list[str], interests: list[str]) -> list[DirectionSuggestion]:
        raw = self._complete([
            {"role": "system", "content": "根据用户真实能力和兴趣提出 1 到 4 个可实践的探索方向。只返回 JSON：{\"directions\":[{\"title\":\"\",\"summary\":\"\",\"reason\":\"\"}]}，不得承诺收入或结果。"},
            {"role": "user", "content": json.dumps({"skills": skills, "interests": interests}, ensure_ascii=False)},
        ], json_mode=True)
        try:
            parsed = json.loads(raw)
            return [DirectionSuggestion(title=str(item["title"])[:160], summary=str(item["summary"])[:1000], reason=str(item["reason"])[:1000]) for item in parsed["directions"][:4] if str(item.get("title", "")).strip()]
        except (json.JSONDecodeError, KeyError, TypeError) as error:
            raise ValueError("AI 探索方向不是有效 JSON") from error


class ResilientAI:
    """优先调用真实模型；网络或格式异常时保持本地功能可用。"""

    def __init__(self, primary: OpenAICompatibleAI) -> None:
        self.primary = primary
        self.fallback_analysis = KeywordSkillExtractor()
        self.fallback_chat = SupportiveChatResponder()
        self.fallback_insights = LocalInsightGenerator()

    def respond(self, content: str) -> str:
        try:
            return self.primary.respond(content)
        except Exception:
            return self.fallback_chat.respond(content)

    def analyze(self, content: str) -> AnalysisResult:
        try:
            return self.primary.analyze(content)
        except Exception:
            return self.fallback_analysis.analyze(content)

    def describe_skill(self, name: str, category: str, evidence: list[str]) -> dict:
        try:
            return self.primary.describe_skill(name, category, evidence)
        except Exception:
            return self.fallback_insights.describe_skill(name, category, evidence)

    def suggest_directions(self, skills: list[str], interests: list[str]) -> list[DirectionSuggestion]:
        try:
            return self.primary.suggest_directions(skills, interests)
        except Exception:
            return self.fallback_insights.suggest_directions(skills, interests)


def build_ai_from_env() -> ResilientAI | None:
    api_key = os.getenv("SHIGUANG_AI_API_KEY", "").strip()
    base_url = os.getenv("SHIGUANG_AI_BASE_URL", "").strip()
    model = os.getenv("SHIGUANG_AI_MODEL", "").strip()
    if not (api_key and base_url and model):
        return None
    try:
        timeout = float(os.getenv("SHIGUANG_AI_TIMEOUT_SECONDS", "30"))
    except ValueError:
        timeout = 30.0
    return ResilientAI(OpenAICompatibleAI(base_url, api_key, model, timeout=timeout))
