import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/app_api.dart';
import 'package:shiguang_app/main.dart';

void main() {
  test('sending a message refreshes the shared conversation record', () async {
    final controller = ConversationController(DemoAppApi());
    addTearDown(controller.dispose);

    await controller.initialize();
    final previousCount = controller.conversations.first.messageCount;
    await controller.send('今天整理了书桌');

    expect(controller.messages.last.role, 'assistant');
    expect(controller.conversations.first.messageCount, previousCount + 2);
    expect(controller.error, isNull);
  });
}
