import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/main.dart';

void main() {
  testWidgets('renders native mobile screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShiguangApp());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01-login.png'),
    );

    await tester.tap(find.text('登录并进入拾光'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02-story.png'),
    );

    await tester.tap(find.text('我的记录').last);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03-records.png'),
    );
  });
}
