import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/voice/voice_bridge_protocol.dart';

void main() {
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
    expect(
      () => VoiceBridgeCommand.parse({'type': 'voice.delete'}),
      throwsFormatException,
    );
    expect(
      () => VoiceBridgeCommand.parse({'type': 'voice.stop'}),
      throwsFormatException,
    );
  });

  test('rejects malformed input', () {
    expect(
      () => VoiceBridgeCommand.parse('not a map'),
      throwsFormatException,
    );
    expect(
      () => VoiceBridgeCommand.parseJson('{bad json'),
      throwsFormatException,
    );
    expect(
      () => VoiceBridgeCommand.parse({
        'type': 'voice.start',
        'sessionId': 'x' * 129,
      }),
      throwsFormatException,
    );
  });

  test('json-encodes recognized text without interpolation', () {
    final encoded = encodeVoiceEvent({
      'type': 'voice.final',
      'sessionId': 's1',
      'text': '他说："hello"\n下一行',
    });
    expect(jsonDecode(encoded)['text'], '他说："hello"\n下一行');
  });
}
