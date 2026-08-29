const test = require('node:test');
const assert = require('node:assert/strict');
const {
  mergeTranscript,
  createVoiceInputCoordinator,
  createDomVoiceInput,
} = require('../assets/web/src/voice-input.js');

function createFakeTransport({available = true} = {}) {
  const listeners = [];
  return {
    available,
    sent: [],
    send: async message => {
      listeners.slice();
      return message;
    },
    subscribe: listener => listeners.push(listener),
    emit: event => listeners.forEach(listener => listener(event)),
  };
}

function setup(overrides = {}) {
  const sent = [];
  const input = {value: '开头'};
  const transport = createFakeTransport(overrides.transport);
  const voice = createVoiceInputCoordinator({
    getInput: () => input,
    submit: element => sent.push(element.value),
    transport,
    finalWaitMs: 10,
    setTimeout,
    clearTimeout,
    ...overrides.coordinator,
  });
  return {sent, input, transport, voice};
}

test('appends transcript to existing text', () => {
  assert.equal(
    mergeTranscript('我今天很开心', 'and I learned Flutter'),
    '我今天很开心 and I learned Flutter',
  );
});

test('explicit stop sends once after final result', async () => {
  const {sent, input, transport, voice} = setup();

  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: '中英 mix'});
  await voice.stop();
  transport.emit({type: 'voice.final', sessionId, text: '中英 mixed'});
  transport.emit({type: 'voice.final', sessionId, text: 'duplicate'});

  assert.deepEqual(sent, ['开头 中英 mixed']);
});

test('empty recognition does not send', async () => {
  const {sent, transport, voice} = setup();
  await voice.start();
  const sessionId = voice.sessionId;
  await voice.stop();
  transport.emit({type: 'voice.final', sessionId, text: ''});
  assert.deepEqual(sent, []);
});

test('timeout sends the best partial once', async () => {
  const {sent, transport, voice} = setup();
  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: 'best partial'});
  await voice.stop();
  await new Promise(resolve => setTimeout(resolve, 20));
  assert.deepEqual(sent, ['开头 best partial']);
});

test('permission error restores base text and does not send', async () => {
  const {sent, input, transport, voice} = setup();
  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: 'temporary'});
  transport.emit({type: 'voice.error', sessionId, code: 'permission_denied'});
  assert.equal(input.value, '开头');
  assert.deepEqual(sent, []);
});

test('idle before explicit stop does not send', async () => {
  const {sent, transport, voice} = setup();
  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: 'unsent'});
  transport.emit({type: 'voice.status', sessionId, status: 'idle'});
  assert.deepEqual(sent, []);
});

test('stale session results do not send', async () => {
  const {sent, transport, voice} = setup();
  await voice.start();
  await voice.stop();
  transport.emit({
    type: 'voice.final',
    sessionId: 'stale-session',
    text: 'should ignore',
  });
  await new Promise(resolve => setTimeout(resolve, 20));
  assert.equal(sent.length, 0);
});

test('cancel does not send', async () => {
  const {sent, input, transport, voice} = setup();
  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: 'temporary'});
  await voice.cancel();
  transport.emit({type: 'voice.final', sessionId, text: 'late final'});
  assert.equal(input.value, '开头');
  assert.deepEqual(sent, []);
});

test('unavailable transport does not send', async () => {
  const {sent, voice} = setup({transport: {available: false}});
  await voice.start();
  assert.equal(voice.sessionId, null);
  assert.equal(sent.length, 0);
});

test('DOM refresh observer does not trigger itself indefinitely', () => {
  const originalDocument = global.document;
  const originalMutationObserver = global.MutationObserver;
  let observerCallback = () => {};
  let mutationCount = 0;

  const textNode = initial => {
    let value = initial;
    return {
      get textContent() { return value; },
      set textContent(next) {
        value = next;
        mutationCount += 1;
        if (mutationCount > 10) throw new Error('self-triggering observer loop');
        observerCallback();
      },
    };
  };
  const label = textNode('旧标签');
  const hint = textNode('旧提示');
  const button = {
    classList: {toggle() {}},
    disabled: false,
    querySelector: selector => selector === 'b' ? label : null,
  };

  global.document = {
    documentElement: {},
    addEventListener() {},
    querySelector(selector) {
      if (selector === '[data-action="voice"]') return button;
      if (selector === '[data-voice-hint]') return hint;
      if (selector === '.composer textarea') return {value: ''};
      return null;
    },
  };
  global.MutationObserver = class {
    constructor(callback) { observerCallback = callback; }
    observe() {}
  };

  try {
    const voice = createDomVoiceInput();
    assert.doesNotThrow(() => voice.configure({submit() {}}));
    assert.ok(mutationCount <= 4, `unexpected mutation count: ${mutationCount}`);
  } finally {
    global.document = originalDocument;
    global.MutationObserver = originalMutationObserver;
  }
});
