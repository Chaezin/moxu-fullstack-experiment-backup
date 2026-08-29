from dataclasses import dataclass


CARD_THRESHOLD = 0.75


@dataclass(frozen=True)
class SkillCandidate:
    name: str
    category: str
    score: float


@dataclass(frozen=True)
class AnalysisResult:
    summary: str
    skills: tuple[SkillCandidate, ...]

    @property
    def card_worthy(self) -> bool:
        return any(skill.score >= CARD_THRESHOLD for skill in self.skills)


class KeywordSkillExtractor:
    """无外部 AI 密钥时使用的保守型中英文混合分析器。"""

    skill_terms = {
        "Flutter 开发": ("flutter", "dart"),
        "公众表达": ("演讲", "表达", "presentation", "public speaking"),
        "编程开发": ("编程", "代码", "python", "coding", "code"),
        "沟通协作": ("沟通", "协作", "communicate", "collaboration", "teamwork"),
        "产品设计": ("设计", "原型", "design", "prototype"),
    }
    categories = {
        "Flutter 开发": "技术",
        "编程开发": "技术",
        "公众表达": "通用能力",
        "沟通协作": "通用能力",
        "产品设计": "创意",
    }
    action_terms = (
        "完成",
        "实现",
        "解决",
        "练习",
        "学会",
        "制作",
        "finished",
        "built",
        "solved",
        "practiced",
        "implemented",
    )

    def analyze(self, content: str) -> AnalysisResult:
        normalized = content.casefold()
        has_action = any(term in normalized for term in self.action_terms)
        score = 0.85 if has_action else 0.45
        skills = tuple(
            SkillCandidate(name=name, category=self.categories[name], score=score)
            for name, terms in self.skill_terms.items()
            if any(term in normalized for term in terms)
        )
        return AnalysisResult(summary=content.strip()[:240], skills=skills)
