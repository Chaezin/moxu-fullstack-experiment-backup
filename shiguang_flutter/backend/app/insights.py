"""从真实能力证据生成可展示的能力说明与探索方向。"""

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class DirectionSuggestion:
    title: str
    summary: str
    reason: str


class InsightGenerator(Protocol):
    def describe_skill(self, name: str, category: str, evidence: list[str]) -> dict: ...
    def suggest_directions(self, skills: list[str], interests: list[str]) -> list[DirectionSuggestion]: ...


class LocalInsightGenerator:
    """真实模型不可用时，以用户自己的技能和证据生成个性化结果。"""

    def describe_skill(self, name: str, category: str, evidence: list[str]) -> dict:
        source = evidence[0] if evidence else f"已经出现了与{name}相关的行动线索。"
        return {
            "summary": f"你在真实行动中反复使用了{name}，这项能力目前属于{category}线索。",
            "typicalBehaviors": [f"主动运用{name}完成具体任务", "把过程整理成可以复用的方法"],
            "suitableScenarios": [f"需要{name}的个人项目", "向他人分享过程和经验"],
            "boundaries": ["当前证据来自有限生活场景，需要更多记录继续验证"],
            "evidenceSummary": source,
        }

    def suggest_directions(self, skills: list[str], interests: list[str]) -> list[DirectionSuggestion]:
        if not skills:
            return []
        primary = skills[0]
        interest = interests[0] if interests else "生活经验"
        return [
            DirectionSuggestion(
                title=f"{primary} × {interest}",
                summary=f"把你的{primary}用于{interest}相关的小项目，并持续记录实际成果。",
                reason=f"来自已确认能力“{primary}”和兴趣“{interest}”。",
            ),
            DirectionSuggestion(
                title=f"分享你的{primary}方法",
                summary=f"把{primary}中的步骤、判断和经验整理成他人容易使用的内容。",
                reason=f"你的真实对话已经出现{primary}的具体行动证据。",
            ),
        ]
