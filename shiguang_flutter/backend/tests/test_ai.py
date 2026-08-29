from app.ai import OpenAICompatibleAI, ResilientAI, build_ai_from_env

def test_ai_chat_uses_openai_compatible_response():
    calls = []
    def request(url, headers, payload, timeout):
        calls.append((url, headers, payload, timeout))
        return {"choices": [{"message": {"content": "你好，我听见了。"}}]}

    ai = OpenAICompatibleAI("https://example.test/v1", "secret", "model-x", request=request)
    assert ai.respond("今天完成了 Flutter 项目") == "你好，我听见了。"
    assert calls[0][0] == "https://example.test/v1/chat/completions"
    assert calls[0][1]["Authorization"] == "Bearer secret"
    assert calls[0][2]["model"] == "model-x"


def test_ai_analysis_parses_structured_json():
    def request(url, headers, payload, timeout):
        return {"choices": [{"message": {"content": '{"summary":"完成项目","skills":[{"name":"Flutter 开发","category":"技术","score":0.91}]}'}}]}

    result = OpenAICompatibleAI("https://example.test/v1", "secret", "model-x", request=request).analyze("我完成了 Flutter 项目")
    assert result.summary == "完成项目"
    assert result.skills[0].name == "Flutter 开发"
    assert result.skills[0].score == 0.91


def test_ai_analysis_rejects_malformed_response():
    def request(url, headers, payload, timeout):
        return {"choices": [{"message": {"content": "not json"}}]}

    ai = OpenAICompatibleAI("https://example.test/v1", "secret", "model-x", request=request)
    try:
        ai.analyze("内容")
    except ValueError as error:
        assert "JSON" in str(error)
    else:
        raise AssertionError("expected malformed AI output to fail")


def test_build_ai_from_env_reads_timeout(monkeypatch):
    monkeypatch.setenv("SHIGUANG_AI_BASE_URL", "https://example.test/v1")
    monkeypatch.setenv("SHIGUANG_AI_API_KEY", "secret")
    monkeypatch.setenv("SHIGUANG_AI_MODEL", "model-x")
    monkeypatch.setenv("SHIGUANG_AI_TIMEOUT_SECONDS", "12.5")

    ai = build_ai_from_env()

    assert isinstance(ai, ResilientAI)
    assert ai.primary.timeout == 12.5


def test_resilient_ai_falls_back_when_provider_fails():
    def request(url, headers, payload, timeout):
        raise RuntimeError("provider unavailable")

    ai = ResilientAI(
        OpenAICompatibleAI("https://example.test/v1", "secret", "model-x", request=request)
    )

    assert "Flutter" in ai.respond("我完成了 Flutter 项目")
    assert ai.analyze("我完成了 Flutter 项目").skills[0].name == "Flutter 开发"


def test_ai_generates_structured_skill_detail_and_directions():
    responses = iter([
        '{"summary":"真实总结","typicalBehaviors":["完成页面"],"suitableScenarios":["产品开发"],"boundaries":["样本有限"],"evidenceSummary":"完成 Flutter 页面"}',
        '{"directions":[{"title":"产品实践","summary":"用 Flutter 完成真实产品","reason":"已有开发证据"}]}',
    ])

    def request(url, headers, payload, timeout):
        return {"choices": [{"message": {"content": next(responses)}}]}

    ai = OpenAICompatibleAI("https://example.test/v1", "secret", "model-x", request=request)
    detail = ai.describe_skill("Flutter 开发", "技术", ["完成 Flutter 页面"])
    directions = ai.suggest_directions(["Flutter 开发"], ["产品设计"])

    assert detail["typicalBehaviors"] == ["完成页面"]
    assert directions[0].title == "产品实践"
