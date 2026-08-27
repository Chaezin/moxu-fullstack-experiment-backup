import test from 'node:test';
import assert from 'node:assert/strict';
import { AGENT_RULE_VERSION, buildChatSystemPrompt } from '../apps/api/agent/prompt.mjs';
import { safetyRoute } from '../apps/api/agent/safety.mjs';

test('聊天提示词按固定规则与唯一任务装配', () => {
  const prompt = buildChatSystemPrompt();
  assert.equal(AGENT_RULE_VERSION, '1.1');
  assert.match(prompt, /角色与目标|你叫“时光”/);
  assert.match(prompt, /对话规则/);
  assert.match(prompt, /安全规则/);
  assert.match(prompt, /隐私规则/);
  assert.match(prompt, /输出边界/);
  assert.match(prompt, /chat_reply/);
  assert.match(prompt, /对话方法/);
});

test('普通疲惫和低落不会被自动升级', () => {
  for (const content of ['今天真的很累', '最近心情有些低落', '我很生气，想先自己待会儿']) {
    assert.equal(safetyRoute([{ role: 'user', content }]).routed, false);
  }
});

test('明确且迫近的自伤表达进入固定安全分流', () => {
  const result = safetyRoute([{ role: 'user', content: '我今晚准备好工具结束生命' }]);
  assert.equal(result.routed, true);
  assert.equal(result.body.code, 'SAFETY_ROUTED');
  assert.equal(result.body.generationPaused, true);
  assert.doesNotMatch(result.body.message, /\d{3,}/);
});

test('安全检查只处理最近一条用户消息', () => {
  const result = safetyRoute([
    { role: 'user', content: '我刚才提到一个危险故事' },
    { role: 'assistant', content: '我们可以换个话题。' },
    { role: 'user', content: '好，我现在想聊今天做的饭。' },
  ]);
  assert.equal(result.routed, false);
});
