import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

Future<void> openVocabularyDetail(WidgetTester tester) async {
  await tester.pumpWidget(const ShiguangApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('登录并进入我是谁'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.person_outline));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('全部能力词库'),
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('全部能力词库'));
  await tester.pumpAndSettle();
}

Future<void> precacheVocabularyAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final asset in const [
      materialIvoryAsset,
      materialBlueAsset,
      materialSageAsset,
      materialClayAsset,
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
    testWidgets('vocabulary has no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openVocabularyDetail(tester);
      expect(find.text('能力词库'), findsWidgets);
      expect(find.byType(VocabularyAbilityCard), findsNWidgets(4));
      expect(find.byType(VocabularyFilterLabel), findsNWidgets(4));
      for (final tile in tester.widgetList<AssetFeltIconTile>(
        find.byType(AssetFeltIconTile),
      )) {
        final box = tester.renderObject<RenderBox>(find.byWidget(tile));
        expect(box.size.width, box.size.height);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('观察力'));
      await tester.pumpAndSettle();
      expect(find.text('能力说明'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders vocabulary golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openVocabularyDetail(tester);
    await precacheVocabularyAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/09-vocabulary.png'),
    );
  });
}
