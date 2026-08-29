import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/voice/speech_recognition_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

final class FakeSpeechToText extends SpeechToText {
  FakeSpeechToText() : super.withMethodChannel();

  int initializeCalls = 0;
  bool initializeResult = true;
  Completer<void>? initializeBlocker;
  SpeechStatusListener? capturedStatus;
  SpeechErrorListener? capturedError;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    initializeCalls++;
    capturedStatus = onStatus;
    capturedError = onError;
    final blocker = initializeBlocker;
    if (blocker != null) {
      await blocker.future;
    }
    return initializeResult;
  }
}

void main() {
  test(
    'DeviceSpeechRecognitionService implements SpeechRecognitionService',
    () {
      final SpeechRecognitionService service = DeviceSpeechRecognitionService();
      expect(service, isA<DeviceSpeechRecognitionService>());
    },
  );

  test(
    'adapter contract exposes initialize, locales, listen, stop, and cancel',
    () {
      final service = DeviceSpeechRecognitionService();
      expect(service.initialize, isA<Function>());
      expect(service.locales, isA<Function>());
      expect(service.listen, isA<Function>());
      expect(service.stop, isA<Function>());
      expect(service.cancel, isA<Function>());
    },
  );

  test(
    'initialize once, keep latest handlers, and return cached availability',
    () async {
      final speech = FakeSpeechToText();
      final service = DeviceSpeechRecognitionService(speech: speech);
      final firstStatuses = <String>[];
      final firstErrors = <String>[];
      final secondStatuses = <String>[];
      final secondErrors = <String>[];

      final firstAvailable = await service.initialize(
        onStatus: firstStatuses.add,
        onError: (code, message, permanent) => firstErrors.add(code),
      );
      expect(firstAvailable, isTrue);
      expect(speech.initializeCalls, 1);

      speech.initializeResult = false;
      final secondAvailable = await service.initialize(
        onStatus: secondStatuses.add,
        onError: (code, message, permanent) => secondErrors.add(code),
      );
      expect(secondAvailable, isTrue);
      expect(speech.initializeCalls, 1);

      speech.capturedStatus?.call('listening');
      speech.capturedError?.call(SpeechRecognitionError('error_network', true));

      expect(firstStatuses, isEmpty);
      expect(firstErrors, isEmpty);
      expect(secondStatuses, ['listening']);
      expect(secondErrors, ['error_network']);
    },
  );

  test('concurrent initialize calls share one plugin initialize', () async {
    final speech = FakeSpeechToText()
      ..initializeBlocker = Completer<void>();
    final service = DeviceSpeechRecognitionService(speech: speech);

    final first = service.initialize(onStatus: (_) {}, onError: (_, _, _) {});
    final second = service.initialize(onStatus: (_) {}, onError: (_, _, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(speech.initializeCalls, 1);

    speech.initializeBlocker!.complete();
    final results = await Future.wait([first, second]);
    expect(results, [true, true]);
    expect(speech.initializeCalls, 1);
  });

  test('retries plugin initialize after the first attempt fails', () async {
    final speech = FakeSpeechToText()..initializeResult = false;
    final service = DeviceSpeechRecognitionService(speech: speech);

    final first = await service.initialize(
      onStatus: (_) {},
      onError: (_, _, _) {},
    );
    expect(first, isFalse);
    expect(speech.initializeCalls, 1);

    speech.initializeResult = true;
    final second = await service.initialize(
      onStatus: (_) {},
      onError: (_, _, _) {},
    );
    expect(second, isTrue);
    expect(speech.initializeCalls, 2);
  });
}
