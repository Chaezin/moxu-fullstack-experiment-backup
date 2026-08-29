# Voice Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add cross-platform Chinese/English speech-to-text input that appends to the current composer text and sends exactly once when the user taps the voice button a second time.

**Architecture:** Flutter owns native speech recognition through `speech_to_text` and exposes a small, validated bridge to the HTML application. The HTML application owns the user interaction, text merge, 1.5-second final-result window, and reuse of `submitChatInput`; standalone Chrome/Edge preview falls back to the Web Speech API. Windows serves the bundled `assets/web` directory through a WebView2 virtual host so every Flutter platform runs the same page and bridge contract.

**Tech Stack:** Flutter 3.47.2, Dart 3.13.2, `speech_to_text` 7.4.0, `webview_flutter` 4.14.1, `webview_flutter_windows` 1.1.1, browser JavaScript, Node 24 test runner.

## Global Constraints

- Target Android, iOS, and Windows; standalone browser preview must degrade through Web Speech API or show an unsupported message.
- Prefer locale `zh-CN`, accept common English words, then fall back to another Chinese locale and finally the system locale.
- Append recognized text to the text present when listening starts.
- Send only after the user explicitly taps the voice button a second time.
- Wait at most 1.5 seconds for the final result, then use the best available partial result.
- Never auto-send on permission denial, error, system timeout, page exit, or empty recognition.
- Do not store or upload raw audio.
- Keep one active voice session and use session IDs to reject stale callbacks.
- Preserve the existing Enter key, send-button, and `submitChatInput()` behavior.
- Windows native verification remains blocked until Developer Mode and the Visual Studio C++/CMake/Windows SDK components are installed.

---

## File Structure

- Create `lib/voice/speech_recognition_service.dart`: platform speech adapter interface and `speech_to_text` implementation.
- Create `lib/voice/voice_input_controller.dart`: native session lifecycle, locale selection, and event emission.
- Create `lib/voice/voice_bridge_protocol.dart`: strict JSON command parsing and event serialization.
- Create `lib/voice/windows_web_assets.dart`: deterministic Windows bundled-asset location and virtual-host constants.
- Create `assets/web/src/voice-input.js`: browser/native transport selection, UI state, text merge, timeout, and one-shot send.
- Create `test/voice/speech_recognition_service_test.dart`: locale and adapter-facing contract tests.
- Create `test/voice/voice_input_controller_test.dart`: native lifecycle and stale-session tests.
- Create `test/voice/voice_bridge_protocol_test.dart`: malformed-message and allowlist tests.
- Create `test/voice/windows_web_assets_test.dart`: Windows asset-root computation tests.
- Create `test/voice_input_web_test.cjs`: Node tests for merge, stop, timeout, error, and duplicate-result behavior.
- Modify `lib/standard_webview_page.dart`: JavaScript Channel and native-to-page event delivery.
- Modify `lib/windows_webview_page.dart`: bundled assets, WebView2 messages, origin check, and native-to-page delivery.
- Modify `lib/main.dart`: construct the new Windows bundled-content page.
- Modify `assets/web/index.html`: load the voice coordinator before `app.js`.
- Modify `assets/web/src/app.js`: remove the visual-only handler and configure the coordinator with `submitChatInput`.
- Modify `android/app/src/main/AndroidManifest.xml`: microphone, Bluetooth, and speech-service visibility declarations.
- Modify `ios/Runner/Info.plist`: microphone and speech-recognition usage descriptions.
- Modify `pubspec.yaml` and `pubspec.lock`: add `speech_to_text: 7.4.0`.

---

### Task 1: Native Speech Service and Session Controller

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/voice/speech_recognition_service.dart`
- Create: `lib/voice/voice_input_controller.dart`
- Test: `test/voice/speech_recognition_service_test.dart`
- Test: `test/voice/voice_input_controller_test.dart`

**Interfaces:**
- Produces: `SpeechRecognitionService.initialize(...)`, `locales()`, `listen(...)`, `stop()`, and `cancel()`.
- Produces: `VoiceInputController.start(sessionId:, preferredLocale:)`, `stop(sessionId:)`, `cancel(sessionId:)`, and `dispose()`.
- Produces events shaped as `Map<String, Object?>` with `type`, `sessionId`, and event-specific fields.

- [ ] **Step 1: Add failing controller tests**

Create a fake service that captures callbacks and verify the lifecycle with concrete assertions:

```dart
final class FakeSpeechRecognitionService
    implements SpeechRecognitionService {
  bool initializeResult = true;
  List<String> supportedLocales = ['en_US', 'zh_CN'];
  SpeechResultHandler? onResult;
  SpeechStatusHandler? onStatus;
  SpeechErrorHandler? onError;
  String? listenedLocale;
  int stopCalls = 0;
  int cancelCalls = 0;

  @override
  Future<bool> initialize({
    required SpeechStatusHandler onStatus,
    required SpeechErrorHandler onError,
  }) async {
    this.onStatus = onStatus;
    this.onError = onError;
    return initializeResult;
  }

  @override
  Future<List<String>> locales() async => supportedLocales;

  @override
  Future<void> listen({
    required String? localeId,
    required SpeechResultHandler onResult,
  }) async {
    listenedLocale = localeId;
    this.onResult = onResult;
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> cancel() async => cancelCalls++;
}

test('prefers zh-CN and emits one final result after explicit stop', () async {
  final service = FakeSpeechRecognitionService();
  final events = <Map<String, Object?>>[];
  final controller = VoiceInputController(
    service: service,
    emit: events.add,
    finalResultWait: const Duration(milliseconds: 10),
  );

  await controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
  expect(service.listenedLocale, 'zh_CN');
  service.onResult?.call('今天 discuss Flutter', false);
  await controller.stop(sessionId: 's1');
  service.onResult?.call('今天 discuss Flutter', true);

  expect(events.where((event) => event['type'] == 'voice.final'), hasLength(1));
  expect(events.lastWhere((event) => event['type'] == 'voice.final')['text'],
      '今天 discuss Flutter');
});

test('ignores stale session stop and callback', () async {
  final service = FakeSpeechRecognitionService();
  final events = <Map<String, Object?>>[];
  final controller = VoiceInputController(
    service: service,
    emit: events.add,
    finalResultWait: const Duration(milliseconds: 10),
  );

  await controller.start(sessionId: 'current', preferredLocale: 'zh-CN');
  await controller.stop(sessionId: 'stale');
  expect(service.stopCalls, 0);
  expect(events.where((event) => event['sessionId'] == 'stale'), isEmpty);
});
```

Add these exact test cases, each with an explicit assertion:

```dart
test('emits unavailable when initialization returns false', () async {
  service.initializeResult = false;
  await controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
  expect(events.last['code'], 'recognition_unavailable');
});

test('falls back to another Chinese locale', () async {
  service.supportedLocales = ['en_US', 'zh_TW'];
  await controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
  expect(service.listenedLocale, 'zh_TW');
});

test('cancel never emits a final result', () async {
  await controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
  service.onResult?.call('partial', false);
  await controller.cancel(sessionId: 's1');
  expect(service.cancelCalls, 1);
  expect(events.where((event) => event['type'] == 'voice.final'), isEmpty);
});

test('permanent errors emit one error and cancel', () async {
  await controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
  service.onError?.call('error_permission', 'permission denied', true);
  expect(events.where((event) => event['type'] == 'voice.error'), hasLength(1));
  expect(service.cancelCalls, 1);
});
```

Use `fake_async` for the final-result timeout test, advance beyond `finalResultWait`, and assert that the last partial is emitted once as `voice.final`. Call `dispose()` in a separate test and assert one cancel with no final event.

- [ ] **Step 2: Run the tests and confirm RED**

Run:

```powershell
& '..\.tooling\flutter\bin\flutter.bat' test test\voice\speech_recognition_service_test.dart test\voice\voice_input_controller_test.dart
```

Expected: FAIL because the service and controller files do not exist.

- [ ] **Step 3: Add the dependency and minimal service interface**

Add exactly this direct dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  speech_to_text: 7.4.0
  webview_flutter: ^4.14.1
  webview_flutter_windows: ^1.1.1
```

Define the adapter boundary:

```dart
typedef SpeechResultHandler = void Function(String text, bool isFinal);
typedef SpeechStatusHandler = void Function(String status);
typedef SpeechErrorHandler = void Function(
  String code,
  String message,
  bool permanent,
);

abstract interface class SpeechRecognitionService {
  Future<bool> initialize({
    required SpeechStatusHandler onStatus,
    required SpeechErrorHandler onError,
  });
  Future<List<String>> locales();
  Future<void> listen({
    required String? localeId,
    required SpeechResultHandler onResult,
  });
  Future<void> stop();
  Future<void> cancel();
}
```

Implement `DeviceSpeechRecognitionService` with `SpeechToText.initialize(finalTimeout: const Duration(milliseconds: 1500))` and:

```dart
await _speech.listen(
  onResult: (result) => onResult(result.recognizedWords, result.finalResult),
  listenOptions: SpeechListenOptions(
    partialResults: true,
    cancelOnError: true,
    listenMode: ListenMode.dictation,
    listenFor: const Duration(seconds: 60),
    pauseFor: const Duration(seconds: 8),
    localeId: localeId,
  ),
);
```

Map `SpeechRecognitionError.errorMsg` and `.permanent` to `SpeechErrorHandler`. Do not log recognized words.

- [ ] **Step 4: Implement the session controller minimally**

Use the following stable surface:

```dart
typedef VoiceEventSink = void Function(Map<String, Object?> event);

final class VoiceInputController {
  VoiceInputController({
    required SpeechRecognitionService service,
    required VoiceEventSink emit,
    Duration finalResultWait = const Duration(milliseconds: 1500),
  });

  Future<void> start({
    required String sessionId,
    String preferredLocale = 'zh-CN',
  });
  Future<void> stop({required String sessionId});
  Future<void> cancel({required String sessionId});
  Future<void> dispose();
}
```

Normalize locale IDs by removing `-` and `_` and lowercasing. Select exact `zh-CN`, then the first locale beginning with `zh`, then `null` for system default. Emit these exact event types: `voice.status`, `voice.partial`, `voice.final`, and `voice.error`. Include `status` for status events and `text` for result events. Deduplicate final events with a per-session boolean.

- [ ] **Step 5: Run focused tests and confirm GREEN**

Run the Task 1 test command again.

Expected: all Task 1 tests PASS with no unhandled timers.

- [ ] **Step 6: Commit Task 1**

```powershell
git add pubspec.yaml pubspec.lock lib/voice/speech_recognition_service.dart lib/voice/voice_input_controller.dart test/voice
git commit -m "feat: add native speech recognition controller"
```

---

### Task 2: Strict Bridge Protocol and Android/iOS WebView Integration

**Files:**
- Create: `lib/voice/voice_bridge_protocol.dart`
- Modify: `lib/standard_webview_page.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Test: `test/voice/voice_bridge_protocol_test.dart`

**Interfaces:**
- Consumes: `VoiceInputController` from Task 1.
- Produces: `VoiceBridgeCommand.parse(Object?)`, with `type`, `sessionId`, and `preferredLocale`.
- Produces: JavaScript global channel `ShiguangVoiceBridge.postMessage(JSON string)`.
- Produces: page callback `window.ShiguangVoiceInput.receive(eventObject)`.

- [ ] **Step 1: Write failing protocol tests**

```dart
test('parses a valid start command', () {
  final command = VoiceBridgeCommand.parse({
    'type': 'voice.start',
    'sessionId': 'session-1',
    'preferredLocale': 'zh-CN',
  });
  expect(command.type, VoiceCommandType.start);
  expect(command.sessionId, 'session-1');
  expect(command.preferredLocale, 'zh-CN');
});

test('rejects unknown type and missing session', () {
  expect(() => VoiceBridgeCommand.parse({'type': 'voice.delete'}),
      throwsFormatException);
  expect(() => VoiceBridgeCommand.parse({'type': 'voice.stop'}),
      throwsFormatException);
});
```

Add the following malformed-input assertions:

```dart
expect(() => VoiceBridgeCommand.parse('not a map'), throwsFormatException);
expect(() => VoiceBridgeCommand.parseJson('{bad json'), throwsFormatException);
expect(
  () => VoiceBridgeCommand.parse({
    'type': 'voice.start',
    'sessionId': 'x' * 129,
  }),
  throwsFormatException,
);
final encoded = encodeVoiceEvent({
  'type': 'voice.final',
  'sessionId': 's1',
  'text': '他说："hello"\n下一行',
});
expect(jsonDecode(encoded)['text'], '他说："hello"\n下一行');
```

- [ ] **Step 2: Run protocol tests and confirm RED**

Run:

```powershell
& '..\.tooling\flutter\bin\flutter.bat' test test\voice\voice_bridge_protocol_test.dart
```

Expected: FAIL because `voice_bridge_protocol.dart` does not exist.

- [ ] **Step 3: Implement strict command parsing**

Accept only `voice.start`, `voice.stop`, and `voice.cancel`; require a non-empty session ID no longer than 128 characters; default `preferredLocale` to `zh-CN`. Provide:

```dart
enum VoiceCommandType { start, stop, cancel }

final class VoiceBridgeCommand {
  const VoiceBridgeCommand({
    required this.type,
    required this.sessionId,
    required this.preferredLocale,
  });

  final VoiceCommandType type;
  final String sessionId;
  final String preferredLocale;

  static VoiceBridgeCommand parse(Object? value);
  static VoiceBridgeCommand parseJson(String source) =>
      parse(jsonDecode(source));
}
```

- [ ] **Step 4: Wire the standard WebView bridge**

In `_StandardWebViewPageState`, create one `DeviceSpeechRecognitionService` and one `VoiceInputController`. Add the JavaScript channel before loading the page:

```dart
..addJavaScriptChannel(
  'ShiguangVoiceBridge',
  onMessageReceived: (message) => _handleVoiceMessage(message.message),
)
```

Dispatch native events safely with JSON encoding, never string interpolation of recognized text:

```dart
Future<void> _emitVoiceEvent(Map<String, Object?> event) =>
    _controller.runJavaScript(
      'window.ShiguangVoiceInput?.receive(${jsonEncode(event)});',
    );
```

Parse messages, route start/stop/cancel to the controller, return `voice.error` with code `invalid_command` on malformed input, and call `voiceController.dispose()` from `dispose()`.

- [ ] **Step 5: Add platform permissions**

Add Android declarations outside `<application>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

Add a second `<intent>` inside the existing `<queries>`:

```xml
<intent>
    <action android:name="android.speech.RecognitionService" />
</intent>
```

Add iOS keys inside the root `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>用于将你的语音转换为对话文字。</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>用于识别你主动输入的语音并转换为文字。</string>
```

- [ ] **Step 6: Run focused tests, analyzer, and commit**

```powershell
& '..\.tooling\flutter\bin\flutter.bat' test test\voice\voice_bridge_protocol_test.dart test\voice\voice_input_controller_test.dart
& '..\.tooling\flutter\bin\flutter.bat' analyze
git add lib/voice/voice_bridge_protocol.dart lib/standard_webview_page.dart android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist test/voice/voice_bridge_protocol_test.dart
git commit -m "feat: bridge voice input to mobile webview"
```

Expected: tests PASS; analyzer reports no issues.

---

### Task 3: Windows Bundled Web App and WebView2 Voice Bridge

**Files:**
- Create: `lib/voice/windows_web_assets.dart`
- Modify: `lib/windows_webview_page.dart`
- Modify: `lib/main.dart`
- Test: `test/voice/windows_web_assets_test.dart`
- Modify: `test/app_test.dart`

**Interfaces:**
- Consumes: `VoiceInputController` and `VoiceBridgeCommand`.
- Produces: `windowsWebAssetRoot(String resolvedExecutable)` and `windowsWebOrigin`.
- Produces: WebView2 page transport through `window.chrome.webview.postMessage(...)` and `message` events.

- [ ] **Step 1: Write failing Windows asset mapping tests**

```dart
test('resolves bundled web directory beside the Windows executable', () {
  final result = windowsWebAssetRoot(
    r'C:\app\shiguang_app.exe',
  ).replaceAll('\\', '/');
  expect(result, 'C:/app/data/flutter_assets/assets/web/');
});

test('uses a stable secure virtual origin', () {
  expect(windowsWebOrigin, 'https://appassets.shiguang');
});
```

- [ ] **Step 2: Run the test and confirm RED**

```powershell
& '..\.tooling\flutter\bin\flutter.bat' test test\voice\windows_web_assets_test.dart
```

Expected: FAIL because the helper does not exist.

- [ ] **Step 3: Implement the path helper**

```dart
import 'dart:io';

const windowsWebHost = 'appassets.shiguang';
const windowsWebOrigin = 'https://$windowsWebHost';

String windowsWebAssetRoot(String resolvedExecutable) => File(
  resolvedExecutable,
).parent.uri.resolve('data/flutter_assets/assets/web/').toFilePath(
  windows: true,
);
```

- [ ] **Step 4: Replace the remote Windows page with bundled assets**

Change `WindowsWebViewPage` so it no longer requires a remote URL. After initialization and before navigation:

```dart
await _controller.addVirtualHostNameMapping(
  windowsWebHost,
  windowsWebAssetRoot(Platform.resolvedExecutable),
  WebviewHostResourceAccessKind.deny,
);
await _controller.loadUrl('$windowsWebOrigin/index.html');
```

Subscribe to `_controller.url` and `_controller.webMessage` before `loadUrl`. Only process voice commands while the current URL starts with `$windowsWebOrigin/`. Route decoded WebView2 maps through `VoiceBridgeCommand.parse` and send events with:

```dart
Future<void> _emitVoiceEvent(Map<String, Object?> event) =>
    _controller.postWebMessage(jsonEncode(event));
```

Dispose the voice controller and all stream subscriptions. Keep popup policy denied.

- [ ] **Step 5: Update application construction and shell tests**

Replace `WindowsWebViewPage(url: shiguangWebUrl)` with `const WindowsWebViewPage()`. Remove `shiguangWebUrl` if no longer referenced. Update `test/app_test.dart` to assert `windowsWebOrigin` and `shiguangWebAsset` remain stable.

- [ ] **Step 6: Run tests and commit**

```powershell
& '..\.tooling\flutter\bin\flutter.bat' test test\voice\windows_web_assets_test.dart test\app_test.dart test\golden_test.dart
& '..\.tooling\flutter\bin\flutter.bat' analyze
git add lib/voice/windows_web_assets.dart lib/windows_webview_page.dart lib/main.dart test/voice/windows_web_assets_test.dart test/app_test.dart
git commit -m "feat: run bundled voice-enabled web app on windows"
```

Expected: tests PASS; analyzer reports no issues. Do not claim a Windows build until the missing system components are installed.

---

### Task 4: Browser Voice Coordinator and Automatic Send

**Files:**
- Create: `assets/web/src/voice-input.js`
- Create: `test/voice_input_web_test.cjs`
- Modify: `assets/web/index.html`
- Modify: `assets/web/src/app.js`

**Interfaces:**
- Consumes: `window.ShiguangVoiceBridge`, `window.chrome.webview`, or `window.SpeechRecognition`/`webkitSpeechRecognition`.
- Consumes: `submitChatInput(input)` through `configure({submit})`.
- Produces: `window.ShiguangVoiceInput.configure(...)`, `.receive(event)`, `.cancel()`, and `.refresh()`.

- [ ] **Step 1: Write failing pure-function and coordinator tests**

Use Node's built-in test runner and require the module in CommonJS mode:

```javascript
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  mergeTranscript,
  createVoiceInputCoordinator,
} = require('../assets/web/src/voice-input.js');

test('appends transcript to existing text', () => {
  assert.equal(
    mergeTranscript('我今天很开心', 'and I learned Flutter'),
    '我今天很开心 and I learned Flutter',
  );
});

test('explicit stop sends once after final result', async () => {
  const sent = [];
  const input = {value: '开头'};
  const transport = createFakeTransport();
  const voice = createVoiceInputCoordinator({
    getInput: () => input,
    submit: element => sent.push(element.value),
    transport,
    finalWaitMs: 10,
    setTimeout,
    clearTimeout,
  });

  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: '中英 mix'});
  await voice.stop();
  transport.emit({type: 'voice.final', sessionId, text: '中英 mixed'});
  transport.emit({type: 'voice.final', sessionId, text: 'duplicate'});

  assert.deepEqual(sent, ['开头 中英 mixed']);
});
```

Add these exact cases using the same fake transport:

```javascript
test('empty recognition does not send', async () => {
  await voice.start();
  const sessionId = voice.sessionId;
  await voice.stop();
  transport.emit({type: 'voice.final', sessionId, text: ''});
  assert.deepEqual(sent, []);
});

test('timeout sends the best partial once', async () => {
  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: 'best partial'});
  await voice.stop();
  await new Promise(resolve => setTimeout(resolve, 20));
  assert.deepEqual(sent, ['开头 best partial']);
});

test('permission error restores base text and does not send', async () => {
  await voice.start();
  const sessionId = voice.sessionId;
  transport.emit({type: 'voice.partial', sessionId, text: 'temporary'});
  transport.emit({type: 'voice.error', sessionId, code: 'permission_denied'});
  assert.equal(input.value, '开头');
  assert.deepEqual(sent, []);
});
```

Repeat the pattern for `voice.status: idle` before explicit stop, a stale session ID, `cancel()`, and an unavailable transport; every case must assert `sent.length === 0`.

- [ ] **Step 2: Run Node tests and confirm RED**

```powershell
node --test test\voice_input_web_test.cjs
```

Expected: FAIL because `voice-input.js` does not exist.

- [ ] **Step 3: Implement transport-independent coordinator**

Wrap the module so Node receives exports and browsers receive `window.ShiguangVoiceInput`:

```javascript
(function (root, factory) {
  const api = factory(root);
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ShiguangVoiceInput = api.createDomVoiceInput();
})(typeof window === 'undefined' ? globalThis : window, function (root) {
  function mergeTranscript(base, transcript) {
    const left = String(base || '').trimEnd();
    const right = String(transcript || '').trim();
    if (!left) return right;
    if (!right) return left;
    return `${left}${/[\s，。！？、,.!?;；:]$/.test(left) ? '' : ' '}${right}`;
  }

  function createVoiceInputCoordinator(options) {
    const {
      getInput,
      submit,
      transport,
      updateUi = () => {},
      finalWaitMs = 1500,
      setTimer = setTimeout,
      clearTimer = clearTimeout,
      createSessionId = () => root.crypto?.randomUUID?.() ||
        `voice-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    } = options;
    let sessionId = null;
    let baseText = '';
    let bestText = '';
    let status = 'idle';
    let stopRequested = false;
    let sent = false;
    let finalTimer = null;

    const setStatus = (next, message) => {
      status = next;
      updateUi({status, message});
    };
    const clearFinalTimer = () => {
      if (finalTimer !== null) clearTimer(finalTimer);
      finalTimer = null;
    };
    const writeDraft = () => {
      const input = getInput();
      if (input) input.value = mergeTranscript(baseText, bestText);
    };
    const reset = () => {
      clearFinalTimer();
      sessionId = null;
      baseText = '';
      bestText = '';
      stopRequested = false;
      sent = false;
      setStatus('idle');
    };
    const finalize = () => {
      if (sent || !stopRequested) return;
      clearFinalTimer();
      const input = getInput();
      if (!input || !bestText.trim()) {
        if (input) input.value = baseText;
        reset();
        return;
      }
      input.value = mergeTranscript(baseText, bestText);
      sent = true;
      submit(input);
      reset();
    };
    const receive = event => {
      if (!event || event.sessionId !== sessionId) return;
      if (event.type === 'voice.partial' || event.type === 'voice.final') {
        bestText = String(event.text || '');
        writeDraft();
        if (event.type === 'voice.final' && stopRequested) finalize();
        return;
      }
      if (event.type === 'voice.error') {
        const input = getInput();
        if (input) input.value = baseText;
        clearFinalTimer();
        updateUi({status: 'error', code: event.code, message: event.message});
        sessionId = null;
        stopRequested = false;
        return;
      }
      if (event.type === 'voice.status') {
        if (event.status === 'idle' && !stopRequested) {
          writeDraft();
          sessionId = null;
          setStatus('idle', '识别已结束，请检查文字后发送或重新录入');
        } else {
          setStatus(event.status, event.message);
        }
      }
    };
    transport.subscribe(receive);

    return {
      get sessionId() { return sessionId; },
      get status() { return status; },
      async start() {
        if (sessionId || !transport.available) return;
        const input = getInput();
        if (!input) return;
        sessionId = createSessionId();
        baseText = input.value;
        bestText = '';
        stopRequested = false;
        sent = false;
        setStatus('requesting');
        await transport.send({
          type: 'voice.start', sessionId, preferredLocale: 'zh-CN',
        });
      },
      async stop() {
        if (!sessionId || stopRequested) return;
        stopRequested = true;
        setStatus('stopping');
        await transport.send({type: 'voice.stop', sessionId});
        finalTimer = setTimer(finalize, finalWaitMs);
      },
      async cancel() {
        if (!sessionId) return;
        const current = sessionId;
        const input = getInput();
        if (input) input.value = baseText;
        reset();
        await transport.send({type: 'voice.cancel', sessionId: current});
      },
      receive,
      refresh: () => updateUi({status}),
    };
  }

  return {mergeTranscript, createVoiceInputCoordinator, createDomVoiceInput};
});
```

Keep the implementation above as the coordinator contract. The DOM wrapper may decorate it, but must not duplicate its session, timeout, or send logic.

- [ ] **Step 4: Implement native and Web Speech transports**

Native selection order:

```javascript
if (root.ShiguangVoiceBridge?.postMessage) {
  return {send: message => root.ShiguangVoiceBridge.postMessage(JSON.stringify(message))};
}
if (root.chrome?.webview?.postMessage) {
  root.chrome.webview.addEventListener('message', event => receive(event.data));
  return {send: message => root.chrome.webview.postMessage(message)};
}
```

If neither exists, use `SpeechRecognition || webkitSpeechRecognition` with `lang = 'zh-CN'`, `interimResults = true`, and `continuous = false`. Convert `onresult`, `onerror`, and `onend` into the same `voice.partial`, `voice.final`, `voice.error`, and `voice.status` events. Never start microphone access before a user click.

- [ ] **Step 5: Wire DOM state and existing sender**

Load the coordinator before `app.js`:

```html
<script src="./src/demo-api.js?v=20260828-5"></script>
<script src="./src/voice-input.js?v=20260829-1"></script>
<script src="./src/app.js?v=20260829-5"></script>
```

Make the initial voice markup deterministic and add a hint selector:

```html
<button class="voice" data-action="voice">
  <span class="wave"><i></i><i></i><i></i><i></i></span><b>说话</b>
</button>
<p data-voice-hint>按一下开始，再按一下结束</p>
```

Remove the old `state.listening=!state.listening` branch. After `submitChatInput` is defined, configure once:

```javascript
window.ShiguangVoiceInput?.configure({submit: submitChatInput});
```

The coordinator uses one capture-phase document click listener for `[data-action="voice"]`, updates the button text/class/disabled state and `[data-voice-hint]`, and uses a `MutationObserver` only to reapply current UI after the existing `render()` replaces the DOM.

- [ ] **Step 6: Run Node tests and browser smoke test**

```powershell
node --test test\voice_input_web_test.cjs
```

Expected: all web voice tests PASS.

Start or reuse the local preview and verify in Chrome/Edge:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory assets/web
```

Expected: first click requests microphone and shows “停止”; partial text appears; second click sends once. Denying permission leaves existing text unchanged.

- [ ] **Step 7: Commit Task 4**

```powershell
git add assets/web/index.html assets/web/src/app.js assets/web/src/voice-input.js test/voice_input_web_test.cjs
git commit -m "feat: add voice transcription to web composer"
```

---

### Task 5: Cross-Platform Verification and Documentation

**Files:**
- Modify: `README.md`
- Modify: `TEAM_HANDOFF.md`
- Modify tests only if verification exposes a missing asserted behavior.

**Interfaces:**
- Consumes the completed Flutter controller, both WebView bridges, and the web coordinator.
- Produces reproducible setup, privacy, and test instructions for future contributors.

- [ ] **Step 1: Run all automated verification**

```powershell
node --test test\voice_input_web_test.cjs
& '..\.tooling\flutter\bin\flutter.bat' test
& '..\.tooling\flutter\bin\flutter.bat' analyze
```

Expected: Node reports zero failures; Flutter reports all tests passed; analyzer reports no issues.

- [ ] **Step 2: Verify repository hygiene**

```powershell
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors; only intended voice-input and documentation changes remain.

- [ ] **Step 3: Perform the available manual matrix**

- Browser Chrome/Edge: allow permission, speak Chinese, English, and a mixed sentence; stop and verify one send.
- Browser error paths: deny permission, say nothing, navigate away, and double-click; verify zero accidental sends.
- Android real device or emulator with microphone: repeat permission and mixed-sentence cases.
- iOS real device: repeat cases; simulator results are informational only.
- Windows native: defer with an explicit note until Developer Mode and the Visual Studio components are installed; do not mark Windows native as passed based only on unit tests.

- [ ] **Step 4: Document usage and limitations**

Add to both docs:

```markdown
## 语音输入

在对话输入区点击“说话”开始识别，再次点击“停止”后，识别文字会追加到已有输入并自动发送。首次使用需要允许麦克风和语音识别权限。应用不保存或上传原始录音。

语音输入面向 60 秒以内的短句。中英文混合识别由设备系统能力提供，不同系统和语言包的准确率可能不同。Windows 支持需在完成本机 Flutter C++ 构建环境后进行真机验收。
```

- [ ] **Step 5: Commit documentation and final verification**

```powershell
git add README.md TEAM_HANDOFF.md
git commit -m "docs: explain cross-platform voice input"
node --test test\voice_input_web_test.cjs
& '..\.tooling\flutter\bin\flutter.bat' test
& '..\.tooling\flutter\bin\flutter.bat' analyze
git status --short
```

Expected: all automated checks pass and the worktree is clean. Report Windows native verification as pending if the system prerequisites remain unavailable.
