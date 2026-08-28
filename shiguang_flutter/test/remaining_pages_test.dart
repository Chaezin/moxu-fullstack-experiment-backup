import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/asset_felt_ui.dart';
import 'package:shiguang_app/main.dart';

Future<void> precacheRemainingAssets(WidgetTester tester) async {
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
}

Future<void> login(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(const ShiguangApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('登录并进入我是谁'));
  await tester.pumpAndSettle();
}

Future<void> openPartners(WidgetTester tester) async {
  await login(tester);
  await tester.tap(find.byIcon(Icons.diamond_outlined));
  await tester.pumpAndSettle();
}

Future<void> openOpportunity(WidgetTester tester) async {
  await openPartners(tester);
  final target = find.text('点击名片，查看探索方向');
  await tester.scrollUntilVisible(
    target,
    450,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> openPartnerDetail(WidgetTester tester) async {
  await openPartners(tester);
  final target = find.text('周宁');
  await tester.scrollUntilVisible(
    target,
    500,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> openPermissionDialog(WidgetTester tester) async {
  await login(tester);
  await tester.tap(find.byKey(const Key('story-permission-button')));
  await tester.pumpAndSettle();
}

void expectSquareAssetTiles(WidgetTester tester) {
  for (final tile in tester.widgetList<AssetFeltIconTile>(
    find.byType(AssetFeltIconTile),
  )) {
    final box = tester.renderObject<RenderBox>(find.byWidget(tile));
    expect(box.size.width, box.size.height);
  }
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
    testWidgets(
      'login and register have no overflow at ${size.width.toInt()} px',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const ShiguangApp());
        await tester.pumpAndSettle();
        expect(find.text('登录个人成长空间'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('还没有账户？创建新账户'));
        await tester.pumpAndSettle();
        expect(find.text('创建你的“我是谁”账户'), findsOneWidget);
        expect(find.text('验证码'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('auth-code')))
              .controller,
          isNull,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('auth-password')))
              .controller!
              .text,
          'Shiguang2026!',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('opportunities have no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openOpportunity(tester);
      expect(find.text('一起能做什么'), findsOneWidget);
      expect(find.byType(OpportunityMaterialCard), findsNWidgets(3));
      expectSquareAssetTiles(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('partner detail has no overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openPartnerDetail(tester);
      expect(find.text('和周宁打个招呼'), findsOneWidget);
      expect(find.text('发送消息'), findsOneWidget);
      expectSquareAssetTiles(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'permission dialog has no overflow at ${size.width.toInt()} px',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await openPermissionDialog(tester);
        expect(find.text('开启表情辅助？'), findsOneWidget);
        expectSquareAssetTiles(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('renders remaining page goldens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShiguangApp());
    await tester.pumpAndSettle();
    await precacheRemainingAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/13-login-felt.png'),
    );
    await tester.tap(find.text('还没有账户？创建新账户'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/13b-register-felt.png'),
    );

    await openOpportunity(tester);
    await precacheRemainingAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/14-opportunities.png'),
    );

    await openPartnerDetail(tester);
    await precacheRemainingAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/15-partner-detail.png'),
    );
    await tester.enterText(find.byType(TextField).last, '你好，想和你一起试试这件小事。');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/15b-partner-detail-lower.png'),
    );

    await openPermissionDialog(tester);
    await precacheRemainingAssets(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/16-permission-dialog.png'),
    );
  });
}
