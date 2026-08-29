from pathlib import Path


WEB_APP = Path(__file__).parents[2] / "assets" / "web" / "src" / "app.js"


def test_web_app_exposes_logout_action_and_clears_session() -> None:
    source = WEB_APP.read_text(encoding="utf-8")

    assert "data-action=\"logout\"" in source
    assert "/api/v1/auth/logout" in source
    assert "localStorage.removeItem('shiguang-token')" in source
    assert "localStorage.removeItem('shiguang-refresh-token')" in source
    assert "localStorage.removeItem('shiguang-device-login')" in source
