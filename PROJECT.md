# 我是谁 APP MVP

一个独立的移动端优先项目，不依赖原 Motion Design Lab。

## 三个一级页面

1. **对话**：文字、语音、用户主动开启的表情辅助；对话结束生成单次成长卡片。
2. **报告**：单次卡片、月度回顾、年度回顾及成长轨迹。
3. **我的**：持续更新的个人档案、能力线索、机会方向、合作入口与隐私控制。

## 建议的正式服务架构

```text
Mobile App
├── Conversation UI
├── Voice Capture → ASR Adapter
├── Camera Consent → On-device Expression Signal
├── Report / Profile / My Content
└── Local permission & cache layer

Application API
├── Conversation Orchestrator
├── LLM Provider Adapter
├── Memory/Profile Service
├── Report Generator
├── Skill Discovery Service
└── Partner Matching Service

Data
├── users
├── consent_records
├── conversations / messages
├── expression_signals (no raw face video by default)
├── conversation_cards
├── profile_facts
├── skill_evidence
├── monthly_reports / annual_reports
└── opportunity_hypotheses / partner_candidates
```

## 本地运行

```bash
python3 -m http.server 8790
```

访问 `http://127.0.0.1:8790/`。

当前为可交互前端 MVP。语音、大模型和面部表情分析使用界面适配层与演示状态，尚未发送真实音视频数据。
