import test from 'node:test';
import assert from 'node:assert/strict';
import { comfort } from '../apps/api/server.mjs';

test('前端约定的 event 能得到 reply 和 actions', async () => {
  const response = comfort({ event: '今天完成了实验' });
  const data = response.body;
  assert.equal(response.status, 200);
  assert.equal(typeof data.reply, 'string');
  assert.ok(Array.isArray(data.actions));
});
