import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

void main() {
  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets('portrait layout has no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ShiguangApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('登录并进入我是谁'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('我的画像'), findsWidgets);
      expect(find.text('已发现的能力线索'), findsOneWidget);
      expect(find.byType(MaterialSkillTile), findsNWidgets(10));
      for (final tile in tester.widgetList<AssetFeltIconTile>(
        find.byType(AssetFeltIconTile),
      )) {
        final box = tester.renderObject<RenderBox>(find.byWidget(tile));
        expect(box.size.width, box.size.height);
      }
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.text('导出我的内容'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
