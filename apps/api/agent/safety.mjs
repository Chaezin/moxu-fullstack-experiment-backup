const IMMEDIATE_DANGER_PATTERNS = [
  /(?:现在|马上|立刻|今晚|今天).{0,12}(?:自杀|轻生|结束生命|杀死自己|伤害自己)/u,
  /(?:自杀|轻生|结束生命|杀死自己).{0,12}(?:计划|方法|工具|地点|遗书|准备好)/u,
  /(?:已经|刚刚|正在).{0,8}(?:割腕|吞药|服毒|上吊|跳楼|伤害自己)/u,
  /(?:我要|准备|打算).{0,8}(?:杀人|杀了|捅死|砍死|伤害他|伤害她|报复他们)/u,
];

export function safetyRoute(messages) {
  const latestUserMessage = [...messages].reverse().find((message) => message.role === 'user');
  const text = latestUserMessage?.content?.trim() || '';
  const matched = IMMEDIATE_DANGER_PATTERNS.some((pattern) => pattern.test(text));
  if (!matched) return { routed: false };
  return {
    routed: true,
    status: 409,
    body: {
      code: 'SAFETY_ROUTED',
      message: '我很在意你此刻的安全。请先离开可能造成伤害的物品或地点，尽快联系身边可信赖的人陪着你，并使用当地紧急服务或前往最近的医疗机构。当前没有可核实的具体热线信息，所以我不会临时提供号码。',
      generationPaused: true,
    },
  };
}
