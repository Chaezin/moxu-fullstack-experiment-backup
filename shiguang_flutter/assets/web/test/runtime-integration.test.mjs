import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import { runInNewContext } from 'node:vm';

const root = new URL('../', import.meta.url);

async function runtimeConfigFor(pageUrl) {
  const source = await readFile(new URL('src/runtime-config.js', root), 'utf8');
  const window = { location: new URL(pageUrl) };
  runInNewContext(source, { URLSearchParams, window });
  return window.__SHIGUANG_CONFIG__;
}

test('runtime config loads before the optional demo adapter', async () => {
  const html = await readFile(new URL('index.html', root), 'utf8');

  assert.match(html, /runtime-config\.js/);
  assert.match(html, /demo-api\.js/);
  assert.ok(html.indexOf('runtime-config.js') < html.indexOf('demo-api.js'));
});

test('demo adapter only intercepts APIs when demo mode is explicit', async () => {
  const source = await readFile(new URL('src/demo-api.js', root), 'utf8');

  assert.match(source, /if \(!demoMode\) return/);
});

test('bundled app origins enable offline demo mode', async () => {
  const bundledPages = [
    'file:///flutter_assets/assets/web/index.html',
    'https://appassets.shiguang/index.html',
  ];

  for (const pageUrl of bundledPages) {
    const config = await runtimeConfigFor(pageUrl);
    assert.equal(config.demoMode, true, pageUrl);
  }
});

test('browser preview stays on the real backend unless demo is requested', async () => {
  const realConfig = await runtimeConfigFor('http://127.0.0.1:8765/index.html');
  const demoConfig = await runtimeConfigFor('http://127.0.0.1:8765/index.html?demo=1');

  assert.equal(realConfig.demoMode, false);
  assert.equal(demoConfig.demoMode, true);
});

test('app uses configured backend and automatic growth-card entry', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /apiBaseUrl/);
  assert.match(source, /clientMessageId/);
  assert.match(source, /查看成长卡片/);
  assert.doesNotMatch(source, /data-action="quick-card"/);
});

test('boot restores a selected conversation and its messages', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /restoreActiveConversation/);
  assert.match(source, /conversations\/\$\{.*\}\/messages/);
});

test('real mode keeps user-scoped cache separate when account changes', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /profile\.id/);
  assert.match(source, /db\.profile\.id/);
  assert.match(source, /db\.conversations=\[\]/);
});

test('real mode does not use localhost as an implicit demo switch', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /const isLocalDevice=window\.__SHIGUANG_DEMO__===true/);
});

test('growth feedback controls call real backend endpoints', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /data-growth-action="confirm-skill"/);
  assert.match(source, /data-growth-action="correct-skill"/);
  assert.match(source, /data-growth-action="hide-skill"/);
  assert.match(source, /\/api\/v1\/skills\/\$\{skill\.id\}/);
  assert.match(source, /data-growth-action="undo-card"/);
  assert.match(source, /\/api\/v1\/cards\/\$\{card\.id\}\/undo/);
  assert.match(source, /data-growth-action="restore-card"/);
  assert.match(source, /\/api\/v1\/cards\/\$\{card\.id\}\/restore/);
});

test('daily card schedule loads from and saves to backend', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /\/api\/v1\/settings\/card-schedule/);
  assert.match(source, /scheduleResult\.schedule/);
  assert.match(source, /method:'PUT'/);
  assert.match(source, /Intl\.DateTimeFormat\(\)\.resolvedOptions\(\)\.timeZone/);
});

test('directions and skill details are loaded from backend', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /\/api\/v1\/directions/);
  assert.match(source, /\/api\/v1\/directions\/refresh/);
  assert.match(source, /\/api\/v1\/skills\/\$\{skill\.id\}/);
  assert.match(source, /selectedSkillDetail/);
  assert.match(source, /recommendationReason/);
});

test('public share links render without requiring login', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /searchParams\.get\('share'\)/);
  assert.match(source, /\/api\/v1\/shared\/\$\{shareToken\}/);
  assert.match(source, /renderSharedProfile/);
});
