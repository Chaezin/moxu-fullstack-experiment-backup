import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

Future<void> openExportDetail(WidgetTester tester) async {
  await tester.pumpWidget(const ShiguangApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('登录并进入我是谁'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.person_outline));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('导出我的内容'),
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text('导出我的内容'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('导出我的内容'));
  await tester.pumpAndSettle();
}

Future<void> precacheExportAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final asset in const [
      materialIvoryAsset,
      materialLandscapeAsset,
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
    testWidgets('export detail has no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openExportDetail(tester);
      expect(find.text('导出预览'), findsOneWidget);
      expect(find.byType(ExportToggleRow), findsNWidgets(3));
      expect(find.byType(Switch), findsNWidgets(3));
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();
      expect(find.text('生成 PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders export detail golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openExportDetail(tester);
    await precacheExportAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/12-export.png'),
    );
  });
}
