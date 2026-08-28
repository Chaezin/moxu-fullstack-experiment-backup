import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

Future<void> openMonthlyDetail(WidgetTester tester) async {
  await tester.pumpWidget(const ShiguangApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('登录并进入我是谁'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.article_outlined));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('查看月度总结'),
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('查看月度总结'));
  await tester.pumpAndSettle();
}

Future<void> precacheMonthlyAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final asset in const [
      materialLandscapeAsset,
      materialIvoryAsset,
      materialBlueAsset,
      materialSageAsset,
      materialMustardAsset,
      materialForestAsset,
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final textLoader = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSansCJKsc-Regular.otf'));
    final serifLoader = FontLoader('NotoSerifSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifSC-VF.ttf'));
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([
      textLoader.load(),
      serifLoader.load(),
      iconLoader.load(),
    ]);
  });

  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets('monthly detail has no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openMonthlyDetail(tester);
      expect(find.text('八月回望'), findsOneWidget);
      expect(find.byType(MonthlyAbilityCard), findsNWidgets(3));
      for (final tile in tester.widgetList<AssetFeltIconTile>(
        find.byType(AssetFeltIconTile),
      )) {
        final box = tester.renderObject<RenderBox>(find.byWidget(tile));
        expect(box.size.width, box.size.height);
      }
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(find.text('下个月可以继续留意'), findsOneWidget);
      expect(find.text('查看这一月'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders monthly detail golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openMonthlyDetail(tester);
    await precacheMonthlyAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/07-monthly-detail.png'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -680),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/07b-monthly-detail-lower.png'),
    );
  });
}
