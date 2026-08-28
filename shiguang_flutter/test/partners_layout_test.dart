import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

void main() {
  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets('partners layout has no overflow at ${size.width.toInt()} px', (
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
      await tester.tap(find.byIcon(Icons.diamond_outlined));
      await tester.pumpAndSettle();

      expect(find.text('我的同路人'), findsWidgets);
      expect(find.text('MY SOCIAL CARD · 01'), findsOneWidget);
      expect(find.text('点击名片，查看探索方向'), findsOneWidget);
      for (final tile in tester.widgetList<AssetFeltIconTile>(
        find.byType(AssetFeltIconTile),
      )) {
        final box = tester.renderObject<RenderBox>(find.byWidget(tile));
        expect(box.size.width, box.size.height);
      }
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.byType(PartnerSuggestionCard), findsNWidgets(3));
      expect(find.text('Mia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
