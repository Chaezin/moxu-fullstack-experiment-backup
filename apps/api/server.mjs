import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const webDir = join(here, '../web');

export function createApp() {
  return createServer(async (req, res) => {
    if (req.method === 'POST' && req.url === '/api/comfort') {
      let raw = '';
      for await (const chunk of req) raw += chunk;
      try {
        const result = comfort(JSON.parse(raw));
        return json(res, result.status, result.body);
      } catch {
        return json(res, 400, { code: 'INVALID_JSON', message: '请求格式不正确' });
      }
    }

    const file = req.url === '/' ? 'index.html' : req.url?.slice(1);
    try {
      const content = await readFile(join(webDir, file || 'index.html'));
      res.writeHead(200, { 'content-type': file?.endsWith('.css') ? 'text/css; charset=utf-8' : file?.endsWith('.js') ? 'text/javascript; charset=utf-8' : 'text/html; charset=utf-8' });
      res.end(content);
    } catch {
      json(res, 404, { code: 'NOT_FOUND', message: '页面不存在' });
    }
  });
}

export function comfort(input) {
  if (typeof input?.event !== 'string' || !input.event.trim()) {
    return { status: 422, body: { code: 'INVALID_EVENT', message: '请先写下一件事' } };
  }
  return { status: 200, body: {
    reply: `我听见了：${input.event.trim()}`,
    actions: ['慢慢呼吸三次', '写下一件今天已经做到的小事'],
    contractVersion: '0.1.0'
  }};
}

function json(res, status, data) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  createApp().listen(4173, () => console.log('Moxu experiment: http://127.0.0.1:4173'));
}
