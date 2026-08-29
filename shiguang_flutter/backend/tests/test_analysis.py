from app.analysis import KeywordSkillExtractor


def test_mixed_chinese_english_action_produces_card_worthy_evidence() -> None:
    extractor = KeywordSkillExtractor()

    result = extractor.analyze("今天我完成了 Flutter presentation demo，并练习了演讲表达。")

    assert result.card_worthy is True
    assert {item.name for item in result.skills} >= {"Flutter 开发", "公众表达"}


def test_skill_mention_without_action_does_not_reach_card_threshold() -> None:
    extractor = KeywordSkillExtractor()

    result = extractor.analyze("我对演讲和 Flutter 有点兴趣。")

    assert result.card_worthy is False
