import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/app_api.dart';

void main() {
  test('NodeAppApi completes auth, conversation and message flow', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final authorizationHeaders = <String?>[];

    server.listen((request) async {
      final path = request.uri.path;
      if (path != '/api/v1/auth/login/password') {
        authorizationHeaders.add(
          request.headers.value(HttpHeaders.authorizationHeader),
        );
      }
      if (path == '/api/v1/auth/login/password') {
        await utf8.decoder.bind(request).join();
        _json(request.response, {
          'token': 'abc123',
          'user': {'id': 'user-1', 'phone': '13800138000'},
        });
      } else if (path == '/api/v1/conversations' && request.method == 'GET') {
        _json(request.response, {
          'conversations': [
            {
              'id': 'talk-1',
              'title': '一次真实对话',
              'mood': '平静',
              'updatedAt': 1788105600000,
              'messageCount': 1,
            },
          ],
        });
      } else if (path == '/api/v1/conversations/talk-1' &&
          request.method == 'GET') {
        _json(request.response, {
          'conversation': {
            'id': 'talk-1',
            'title': '一次真实对话',
            'mood': '平静',
            'updatedAt': 1788105600000,
            'messageCount': 1,
          },
          'messages': [
            {
              'id': 'msg-1',
              'role': 'assistant',
              'content': '我在听。',
              'createdAt': 1788105600000,
            },
          ],
        });
      } else if (path == '/api/v1/conversations/talk-1/messages') {
        final payload = jsonDecode(await utf8.decoder.bind(request).join());
        expect(payload['content'], '今天整理了书桌');
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write('这件小事里，也能看见你的整理能力。');
        await request.response.close();
      } else if (path == '/api/v1/auth/logout') {
        _json(request.response, {'ok': true});
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });

    final api = NodeAppApi(baseUrl: 'http://127.0.0.1:${server.port}');
    final session = await api.login(
      phone: '13800138000',
      password: 'Shiguang2026!',
    );
    final conversations = await api.listConversations();
    final detail = await api.getConversation('talk-1');
    final reply = await api.sendMessage('talk-1', '今天整理了书桌');
    await api.logout();

    expect(session.phone, '13800138000');
    expect(conversations.single.title, '一次真实对话');
    expect(detail.messages.single.content, '我在听。');
    expect(reply.content, '这件小事里，也能看见你的整理能力。');
    expect(authorizationHeaders, everyElement('Bearer abc123'));
  });

  test('NodeAppApi exposes the server error message', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      _json(request.response, {
        'code': 'INVALID_CREDENTIALS',
        'message': '账号或密码不正确。',
      }, statusCode: HttpStatus.unauthorized);
    });
    final api = NodeAppApi(baseUrl: 'http://127.0.0.1:${server.port}');

    await expectLater(
      api.login(phone: '13800138000', password: 'wrong'),
      throwsA(
        isA<AppApiException>().having(
          (error) => error.message,
          'message',
          '账号或密码不正确。',
        ),
      ),
    );
  });
}

void _json(
  HttpResponse response,
  Map<String, dynamic> value, {
  int statusCode = HttpStatus.ok,
}) {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(value))
    ..close();
}
