import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/voice/speech_recognition_service.dart';
import 'package:shiguang_app/voice/voice_input_controller.dart';

final class FakeSpeechRecognitionService implements SpeechRecognitionService {
  bool initializeResult = true;
  List<String> supportedLocales = ['en_US', 'zh_CN'];
  SpeechResultHandler? onResult;
  SpeechStatusHandler? onStatus;
  SpeechErrorHandler? onError;
  String? listenedLocale;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  Completer<void>? stopBlocker;
  Completer<void>? cancelBlocker;
  bool _listenersAssigned = false;

  @override
  Future<bool> initialize({
    required SpeechStatusHandler onStatus,
    required SpeechErrorHandler onError,
  }) async {
    if (!_listenersAssigned && initializeResult) {
      this.onStatus = onStatus;
      this.onError = onError;
      _listenersAssigned = true;
    }
    return initializeResult;
  }

  @override
  Future<List<String>> locales() async => supportedLocales;

  @override
  Future<void> listen({
    required String? localeId,
    required SpeechResultHandler onResult,
  }) async {
    listenCalls++;
    listenedLocale = localeId;
    this.onResult = onResult;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    final blocker = stopBlocker;
    if (blocker != null) {
      await blocker.future;
    }
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
    final blocker = cancelBlocker;
    if (blocker != null) {
      await blocker.future;
    }
  }
}

void main() {
  late FakeSpeechRecognitionService service;
  late List<Map<String, Object?>> events;
  late VoiceInputController controller;

  setUp(() {
    service = FakeSpeechRecognitionService();
    events = <Map<String, Object?>>[];
    controller = VoiceInputController(
      service: service,
      emit: events.add,
      finalResultWait: const Duration(milliseconds: 10),
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  test(
    'prefers zh-CN and emits one final result after explicit stop',
    () async {
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

      expect(
        events.where((event) => event['type'] == 'voice.final'),
        hasLength(1),
      );
      expect(
        events.lastWhere((event) => event['type'] == 'voice.final')['text'],
        '今天 discuss Flutter',
      );
      await controller.dispose();
    },
  );

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
    await controller.dispose();
  });

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
    await Future<void>.delayed(Duration.zero);
    expect(
      events.where((event) => event['type'] == 'voice.error'),
      hasLength(1),
    );
    expect(service.cancelCalls, 1);
  });

  test('emits last partial as final after wait timeout', () {
    fakeAsync((async) {
      final service = FakeSpeechRecognitionService();
      final events = <Map<String, Object?>>[];
      final controller = VoiceInputController(
        service: service,
        emit: events.add,
        finalResultWait: const Duration(milliseconds: 10),
      );

      controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
      async.flushMicrotasks();
      service.onResult?.call('best partial', false);
      controller.stop(sessionId: 's1');
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 11));

      expect(
        events.where((event) => event['type'] == 'voice.final'),
        hasLength(1),
      );
      expect(
        events.lastWhere((event) => event['type'] == 'voice.final')['text'],
        'best partial',
      );

      controller.dispose();
      async.flushMicrotasks();
    });
  });

  test(
    'ignores leftover result and error callbacks from a previous session',
    () async {
      await controller.start(sessionId: 'A', preferredLocale: 'zh-CN');
      service.onResult?.call('from A', false);
      final leftoverResult = service.onResult;

      await controller.start(sessionId: 'B', preferredLocale: 'zh-CN');
      service.onResult?.call('from B', false);

      leftoverResult?.call('A leftover', false);
      leftoverResult?.call('A leftover final', true);

      expect(
        events.where(
          (event) =>
              event['text'] == 'A leftover' ||
              event['text'] == 'A leftover final',
        ),
        isEmpty,
      );
      expect(service.cancelCalls, 1);

      final bPartials = events.where(
        (event) =>
            event['type'] == 'voice.partial' && event['sessionId'] == 'B',
      );
      expect(bPartials.map((event) => event['text']), contains('from B'));
      expect(
        bPartials.map((event) => event['text']),
        isNot(contains('A leftover')),
      );

      await controller.stop(sessionId: 'B');
      service.onResult?.call('from B', true);

      final finals = events.where((event) => event['type'] == 'voice.final');
      expect(finals, hasLength(1));
      expect(finals.single['text'], 'from B');
      expect(finals.single['sessionId'], 'B');
    },
  );

  test(
    'final wait starts when stop is requested, not after service.stop returns',
    () {
      fakeAsync((async) {
        final service = FakeSpeechRecognitionService()
          ..stopBlocker = Completer<void>();
        final events = <Map<String, Object?>>[];
        const wait = Duration(milliseconds: 10);
        final controller = VoiceInputController(
          service: service,
          emit: events.add,
          finalResultWait: wait,
        );

        controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
        async.flushMicrotasks();
        service.onResult?.call('hello', false);
        controller.stop(sessionId: 's1');
        async.flushMicrotasks();
        async.elapse(wait);

        expect(
          events.where((event) => event['type'] == 'voice.final'),
          hasLength(1),
        );
        expect(
          events.lastWhere((event) => event['type'] == 'voice.final')['text'],
          'hello',
        );

        controller.dispose();
        async.flushMicrotasks();
      });
    },
  );

  test('empty result does not wipe last non-empty partial', () {
    fakeAsync((async) {
      final service = FakeSpeechRecognitionService();
      final events = <Map<String, Object?>>[];
      final controller = VoiceInputController(
        service: service,
        emit: events.add,
        finalResultWait: const Duration(milliseconds: 10),
      );

      controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
      async.flushMicrotasks();
      service.onResult?.call('hello', false);
      service.onResult?.call('', false);
      service.onResult?.call('   ', false);
      controller.stop(sessionId: 's1');
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 11));

      expect(
        events.where((event) => event['type'] == 'voice.final'),
        hasLength(1),
      );
      expect(
        events.lastWhere((event) => event['type'] == 'voice.final')['text'],
        'hello',
      );

      controller.dispose();
      async.flushMicrotasks();
    });
  });

  test('dispose cancels without a final result', () async {
    await controller.start(sessionId: 's1', preferredLocale: 'zh-CN');
    service.onResult?.call('partial', false);
    await controller.dispose();
    expect(service.cancelCalls, 1);
    expect(events.where((event) => event['type'] == 'voice.final'), isEmpty);
  });

  test(
    'first-registered status and error listeners still serve later sessions',
    () async {
      await controller.start(sessionId: 'A', preferredLocale: 'zh-CN');
      final originalStatus = service.onStatus;
      final originalError = service.onError;

      await controller.start(sessionId: 'B', preferredLocale: 'zh-CN');
      expect(service.onStatus, same(originalStatus));
      expect(service.onError, same(originalError));

      originalStatus?.call('listening');
      originalError?.call('error_network', 'network error', false);

      expect(
        events.where(
          (event) =>
              event['type'] == 'voice.status' &&
              event['sessionId'] == 'B' &&
              event['status'] == 'listening',
        ),
        isNotEmpty,
      );
      expect(
        events.where(
          (event) =>
              event['type'] == 'voice.error' && event['sessionId'] == 'B',
        ),
        isNotEmpty,
      );
    },
  );

  test(
    'start waits for chained stop and cancel before listen',
    () async {
      service.stopBlocker = Completer<void>();
      service.cancelBlocker = Completer<void>();
      await controller.start(sessionId: 'A', preferredLocale: 'zh-CN');
      expect(service.listenCalls, 1);

      final stopFuture = controller.stop(sessionId: 'A');
      final cancelFuture = controller.cancel(sessionId: 'A');
      final startB = controller.start(sessionId: 'B', preferredLocale: 'zh-CN');
      await Future<void>.delayed(Duration.zero);

      expect(service.listenCalls, 1);
      expect(service.cancelCalls, 0);

      service.stopBlocker!.complete();
      await stopFuture;
      await Future<void>.delayed(Duration.zero);
      expect(service.listenCalls, 1);
      expect(service.cancelCalls, 1);

      service.cancelBlocker!.complete();
      await cancelFuture;
      await startB;
      expect(service.listenCalls, 2);
    },
  );

  test('start waits for in-flight stop before listen', () async {
    service.stopBlocker = Completer<void>();
    await controller.start(sessionId: 'A', preferredLocale: 'zh-CN');
    expect(service.listenCalls, 1);

    final stopFuture = controller.stop(sessionId: 'A');
    final startB = controller.start(sessionId: 'B', preferredLocale: 'zh-CN');
    await Future<void>.delayed(Duration.zero);

    expect(service.listenCalls, 1);

    service.stopBlocker!.complete();
    await stopFuture;
    await startB;
    expect(service.listenCalls, 2);
  });

  test('start waits for in-flight stop after timeout clears the session', () {
    fakeAsync((async) {
      final stopBlocker = Completer<void>();
      final service = FakeSpeechRecognitionService()..stopBlocker = stopBlocker;
      final events = <Map<String, Object?>>[];
      final controller = VoiceInputController(
        service: service,
        emit: events.add,
        finalResultWait: const Duration(milliseconds: 10),
      );

      controller.start(sessionId: 'A', preferredLocale: 'zh-CN');
      async.flushMicrotasks();
      expect(service.listenCalls, 1);

      controller.stop(sessionId: 'A');
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 11));
      expect(
        events.where((event) => event['type'] == 'voice.final'),
        hasLength(1),
      );

      var startBDone = false;
      controller.start(sessionId: 'B', preferredLocale: 'zh-CN').then((_) {
        startBDone = true;
      });
      async.flushMicrotasks();
      expect(startBDone, isFalse);
      expect(service.listenCalls, 1);

      stopBlocker.complete();
      async.flushMicrotasks();
      expect(startBDone, isTrue);
      expect(service.listenCalls, 2);

      controller.dispose();
      async.flushMicrotasks();
    });
  });
}
