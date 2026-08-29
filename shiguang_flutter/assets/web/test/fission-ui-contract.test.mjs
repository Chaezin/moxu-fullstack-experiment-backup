import assert from 'node:assert/strict';
import { access, readFile } from 'node:fs/promises';
import test from 'node:test';

const root = new URL('../', import.meta.url);

test('fission felt UI assets are loaded without dropping local runtime bridges', async () => {
  const html = await readFile(new URL('index.html', root), 'utf8');

  assert.match(html, /login-felt-v1\.css/);
  assert.match(html, /app-felt-v1\.css/);
  assert.match(html, /fission-ui-overrides\.css/);
  assert.match(html, /runtime-config\.js/);
  assert.match(html, /voice-input\.js/);

  await Promise.all([
    'src/login-felt-v1.css',
    'src/app-felt-v1.css',
    'src/fission-ui-overrides.css',
    'src/assets/felt-ui/felt-card-surface-v1.png',
    'src/assets/felt-ui/felt-pressed-neutral-v2.png',
    'src/assets/felt-ui/material-blue-botanical-v1.png',
    'src/assets/felt-ui/material-clay-botanical-v1.png',
    'src/assets/felt-ui/material-forest-botanical-v1.png',
    'src/assets/felt-ui/material-ivory-botanical-v1.png',
    'src/assets/felt-ui/material-mustard-geometric-v1.png',
    'src/assets/felt-ui/material-sage-botanical-v1.png',
    'src/assets/felt-ui/material-story-landscape-v1.png',
  ].map((path) => access(new URL(path, root))));
});

test('partner discovery UI remains rendered by the local behavior layer', async () => {
  const source = await readFile(new URL('src/app.js', root), 'utf8');

  assert.match(source, /title:'寻找伯牙'/);
  assert.match(source, /class="partner-list"/);
  assert.match(source, /data-open="real-partner-chat-\$\{i\}"/);
});
