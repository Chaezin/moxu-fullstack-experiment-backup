import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

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

  testWidgets('renders the felt story screen at mobile DPR 3', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShiguangApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('登录并进入我是谁'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      for (final asset in const [
        materialLandscapeAsset,
        materialIvoryAsset,
        materialBlueAsset,
        materialSageAsset,
        materialClayAsset,
        materialMustardAsset,
        materialForestAsset,
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02-story-felt@3x.png'),
    );
  });
}
