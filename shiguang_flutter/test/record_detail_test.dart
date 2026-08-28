import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

Future<void> openRecordDetail(WidgetTester tester) async {
  await tester.pumpWidget(const ShiguangApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('登录并进入我是谁'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.article_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text('让杂乱重新有秩序'));
  await tester.pumpAndSettle();
}

Future<void> precacheRecordAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final asset in const [
      materialIvoryAsset,
      materialBlueAsset,
      materialSageAsset,
      materialMustardAsset,
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
    testWidgets('record detail has no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openRecordDetail(tester);
      expect(find.text('记录详情'), findsOneWidget);
      expect(find.byType(EvidenceLine), findsNWidgets(3));
      for (final tile in tester.widgetList<AssetFeltIconTile>(
        find.byType(AssetFeltIconTile),
      )) {
        final box = tester.renderObject<RenderBox>(find.byWidget(tile));
        expect(box.size.width, box.size.height);
      }
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -850),
      );
      await tester.pumpAndSettle();
      expect(find.text('查看相关证据'), findsOneWidget);
      expect(find.text('修正'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders record detail golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openRecordDetail(tester);
    await precacheRecordAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/06-record-detail.png'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/06b-record-detail-lower.png'),
    );
  });
}
