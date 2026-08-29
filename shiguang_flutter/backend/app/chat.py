from typing import Protocol


class ChatResponder(Protocol):
    def respond(self, content: str) -> str: ...


class SupportiveChatResponder:
    """外部对话模型未配置时的可用兜底回复器。"""

    def respond(self, content: str) -> str:
        excerpt = content.strip()[:36]
        return (
            f"我听见了。你提到“{excerpt}”，这件事里有你正在形成的方法。"
            "愿意再说说，哪个具体瞬间最能代表你的成长吗？"
        )
