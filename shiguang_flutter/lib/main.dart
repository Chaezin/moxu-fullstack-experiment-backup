import 'package:flutter/material.dart';

import 'asset_felt_ui.dart';
import 'felt_ui.dart';

void main() => runApp(const ShiguangApp());
const ink = feltInk,
    pine = feltForest,
    mist = feltCream,
    paper = feltIvory,
    line = feltLine;

class ShiguangApp extends StatelessWidget {
  const ShiguangApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '我是谁',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: pine, surface: paper),
      scaffoldBackgroundColor: feltCream,
      useMaterial3: true,
      fontFamily: 'NotoSansSC',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.2,
          fontFamily: 'NotoSerifSC',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ink,
          fontFamily: 'NotoSerifSC',
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: ink,
          fontFamily: 'NotoSerifSC',
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: feltMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: feltIvory,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pine, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: feltForest,
          foregroundColor: feltIvory,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          elevation: 2,
          shadowColor: const Color(0x40342C27),
        ),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool register = false, loggedIn = false;
  final phone = TextEditingController(text: '13800138000'),
      password = TextEditingController(text: 'Shiguang2026!');
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loggedIn) return const HomeShell();
    return Scaffold(
      body: AssetMaterialBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 20),
                    const AssetFeltSurface(
                      color: feltIvory,
                      surfaceAsset: materialLandscapeAsset,
                      textureOpacity: 1,
                      radius: 22,
                      depth: 2,
                      padding: EdgeInsets.fromLTRB(20, 18, 20, 15),
                      child: SizedBox(
                        height: 116,
                        child: Stack(
                          children: [
                            Positioned(
                              left: -20,
                              right: -20,
                              top: -18,
                              height: 92,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFF7F1E8),
                                      Color(0xF2F7F1E8),
                                      Color(0x00F7F1E8),
                                    ],
                                    stops: [0, .72, 1],
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '在成为谁之前，\n先看见此刻的自己。',
                              style: TextStyle(
                                fontFamily: 'NotoSerifSC',
                                fontSize: 20,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 23),
                    Text(
                      register ? '创建你的“我是谁”账户' : '登录个人成长空间',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      register
                          ? '完成验证，开始保存属于你的故事。'
                          : '继续记录故事、整理能力线索，并与同路人保持联系。',
                    ),
                    const SizedBox(height: 18),
                    AssetFeltSurface(
                      color: feltIvory,
                      surfaceAsset: materialIvoryAsset,
                      textureOpacity: .62,
                      radius: 21,
                      depth: 1.5,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextField(
                            key: const Key('auth-phone'),
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: '手机号账号',
                              prefixIcon: Icon(Icons.phone_iphone_rounded),
                            ),
                          ),
                          if (register) ...[
                            const SizedBox(height: 12),
                            const TextField(
                              key: Key('auth-code'),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '验证码',
                                prefixIcon: Icon(Icons.verified_outlined),
                                suffixText: '发送验证码',
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('auth-password'),
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: '账号密码',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    MaterialPrimaryButton(
                      label: register ? '注册并进入我是谁' : '登录并进入我是谁',
                      onTap: () => setState(() => loggedIn = true),
                    ),
                    TextButton(
                      onPressed: () => setState(() => register = !register),
                      child: Text(register ? '已经有账户？返回登录' : '还没有账户？创建新账户'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '测试账号：13800138000  ·  密码：Shiguang2026!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MaterialPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const MaterialPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => AssetFeltSurface(
    color: feltForest,
    surfaceAsset: materialForestAsset,
    textureOpacity: .92,
    radius: 17,
    depth: 2,
    padding: EdgeInsets.zero,
    onTap: onTap,
    child: SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: feltIvory, size: 19),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: feltIvory,
              fontFamily: 'NotoSerifSC',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '我是谁',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 25,
          letterSpacing: 2,
          color: feltForest,
        ),
      ),
      SizedBox(height: 2),
      Text(
        'PRIVATE GROWTH ARCHIVE',
        style: TextStyle(fontSize: 8, letterSpacing: 1.3, color: feltMuted),
      ),
    ],
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const double railWidth = 74;
  static const double collapsedRailWidth = 44;
  int index = 0;
  bool railOpen = true;
  final pages = const [
    StoryPage(),
    RecordsPage(),
    PortraitPage(),
    PartnersPage(),
  ];
  final destinations = const [
    NavigationDestination(
      icon: AssetFeltIconTile(
        icon: Icons.chat_bubble_outline,
        color: feltSage,
        size: 42,
        glyph: FlatSpeechGlyph(),
        surfaceAsset: materialSageAsset,
      ),
      selectedIcon: AssetFeltIconTile(
        icon: Icons.chat_bubble_outline,
        color: feltSage,
        size: 42,
        glyph: FlatSpeechGlyph(),
        surfaceAsset: materialSageAsset,
        selectedSurfaceAsset: materialForestAsset,
      ),
      label: '我的故事',
    ),
    NavigationDestination(
      icon: AssetFeltIconTile(
        icon: Icons.article_outlined,
        color: feltClay,
        size: 42,
        surfaceAsset: materialClayAsset,
      ),
      selectedIcon: AssetFeltIconTile(
        icon: Icons.article_outlined,
        color: feltClay,
        size: 42,
        selected: true,
        surfaceAsset: materialClayAsset,
        selectedSurfaceAsset: materialForestAsset,
      ),
      label: '我的记录',
    ),
    NavigationDestination(
      icon: AssetFeltIconTile(
        icon: Icons.person_outline,
        color: feltBlue,
        size: 42,
        surfaceAsset: materialBlueAsset,
      ),
      selectedIcon: AssetFeltIconTile(
        icon: Icons.person_outline,
        color: feltBlue,
        size: 42,
        selected: true,
        surfaceAsset: materialBlueAsset,
        selectedSurfaceAsset: materialForestAsset,
      ),
      label: '我的画像',
    ),
    NavigationDestination(
      icon: AssetFeltIconTile(
        icon: Icons.diamond_outlined,
        color: feltMustard,
        size: 42,
        surfaceAsset: materialMustardAsset,
      ),
      selectedIcon: AssetFeltIconTile(
        icon: Icons.diamond_outlined,
        color: feltMustard,
        size: 42,
        selected: true,
        surfaceAsset: materialMustardAsset,
        selectedSurfaceAsset: materialForestAsset,
      ),
      label: '我的同路人',
    ),
  ];

  void selectPage(int value) {
    setState(() {
      index = value;
      railOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: feltCream,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final mobileWidth = constraints.maxWidth.clamp(0.0, 480.0).toDouble();
        return Center(
          child: SizedBox(
            width: mobileWidth,
            height: constraints.maxHeight,
            child: Material(
              color: feltCream,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: railOpen ? railWidth : collapsedRailWidth,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      color: feltIvory,
                      border: Border(right: BorderSide(color: line)),
                    ),
                    child: railOpen
                        ? OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: railWidth,
                            maxWidth: railWidth,
                            child: SafeArea(
                              child: NavigationRail(
                                backgroundColor: feltIvory,
                                minWidth: railWidth,
                                groupAlignment: index == 0 ? -1 : -.55,
                                selectedIndex: index,
                                labelType: index == 0
                                    ? NavigationRailLabelType.none
                                    : NavigationRailLabelType.all,
                                selectedLabelTextStyle: const TextStyle(
                                  color: feltForest,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'NotoSansSC',
                                ),
                                unselectedLabelTextStyle: const TextStyle(
                                  color: feltMuted,
                                  fontSize: 10,
                                  fontFamily: 'NotoSansSC',
                                ),
                                leading: Tooltip(
                                  message: '隐藏侧边栏',
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => railOpen = false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        index == 0 ? '我是谁' : '我是\n谁',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: feltForest,
                                          fontSize: index == 0 ? 17 : 16,
                                          height: 1.05,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'NotoSerifSC',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                onDestinationSelected: selectPage,
                                destinations: [
                                  for (final destination in destinations)
                                    NavigationRailDestination(
                                      icon: destination.icon,
                                      selectedIcon: destination.selectedIcon,
                                      label: Text(
                                        destination.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : SafeArea(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 84),
                                child: IconButton(
                                  tooltip: '打开侧边栏',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      setState(() => railOpen = true),
                                  icon: const Icon(Icons.keyboard_arrow_right),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: FeltBackdrop(
                      child: IndexedStack(index: index, children: pages),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class PageFrame extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final List<Widget> children;
  const PageFrame({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: '隐私中心',
                  onPressed: () =>
                      openDetail(context, '隐私与记忆', const PrivacyContent()),
                  icon: const Icon(Icons.shield_outlined),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.7,
                      color: pine,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 44),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    ),
  );
}

class StoryPage extends StatefulWidget {
  const StoryPage({super.key});
  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final input = TextEditingController();
  final messages = [
    '晚上好，林溪。今天有没有一件很小、但让你觉得“这是我做出来的”的事情？',
    '我把阳台重新整理了一下，还给每盆植物做了标签。',
    '这不只是整理。你在观察植物的需要，也建立了一套自己的分类方法。你最满意哪个决定？',
  ];

  void sendMessage() {
    if (input.text.trim().isEmpty) return;
    setState(() {
      messages.add(input.text.trim());
      input.clear();
    });
  }

  Widget bubble(int i) {
    final mine = i == 1;
    final height = i == 0
        ? 134.0
        : i == 1
        ? 90.0
        : 150.0;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        height: height,
        width: mine ? 258 : 270,
        child: AssetFeltSurface(
          color: mine ? feltBlue : feltIvory,
          surfaceAsset: mine ? materialBlueAsset : materialIvoryAsset,
          padding: const EdgeInsets.fromLTRB(17, 14, 17, 13),
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!mine) ...[
                const Text(
                  '我是谁',
                  style: TextStyle(
                    color: feltForest,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                messages[i],
                maxLines: i == 2 ? 4 : 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.62),
              ),
              if (mine)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.done_all_rounded,
                    size: 17,
                    color: feltClay,
                  ),
                ),
              if (i == 2) ...[
                const SizedBox(height: 5),
                const Text(
                  '你可以慢慢想，我在听。',
                  style: TextStyle(fontSize: 10.5, color: feltMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AssetMaterialBackdrop(
    child: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 176,
              child: Image.asset(
                materialLandscapeAsset,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                bubble(0),
                const SizedBox(height: 14),
                bubble(1),
                const SizedBox(height: 25),
                bubble(2),
                const SizedBox(height: 25),
                SizedBox(
                  height: 168,
                  child: AssetFeltSurface(
                    color: feltIvory,
                    surfaceAsset: materialIvoryAsset,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    radius: 21,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const FeltIconTile(
                              icon: Icons.adjust_rounded,
                              color: feltSage,
                              size: 34,
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '表情辅助',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '由你决定',
                                    style: TextStyle(
                                      color: feltMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('情绪信号', style: TextStyle(fontSize: 11)),
                                Text(
                                  '平静 · 低焦虑',
                                  style: TextStyle(
                                    color: feltMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                key: const Key('story-permission-button'),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => const PermissionDialog(),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 24),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: input,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: '输入你的想法…',
                                    hintStyle: TextStyle(fontSize: 14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => sendMessage(),
                                ),
                              ),
                              SizedBox(
                                width: 68,
                                height: 70,
                                child: AssetFeltSurface(
                                  color: feltForest,
                                  surfaceAsset: materialForestAsset,
                                  padding: EdgeInsets.zero,
                                  radius: 20,
                                  depth: 2,
                                  onTap: sendMessage,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.graphic_eq_rounded,
                                        size: 24,
                                        color: feltIvory,
                                      ),
                                      Text(
                                        '说话',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: feltIvory,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '按一下开始，再按一下结束',
                          style: TextStyle(fontSize: 9.5, color: feltMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 70),
                OutlinedButton.icon(
                  onPressed: () =>
                      openDetail(context, '本次成长卡片', const CardDetail()),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('整理这次对话'),
                ),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});
  @override
  Widget build(BuildContext context) => AssetMaterialBackdrop(
    child: PageFrame(
      eyebrow: 'PAST CONVERSATION CARDS',
      title: '我的记录',
      subtitle: '往日名片回顾',
      children: [
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final narrow = box.maxWidth < 250;
            final first = RecordCard(
              title: '让杂乱重新有秩序',
              date: '08.19',
              icon: Icons.eco_outlined,
              color: feltSage,
              iconSurfaceAsset: materialSageAsset,
              onTap: () => openDetail(context, '记录详情', const CardDetail()),
            );
            final second = RecordCard(
              title: '我其实很会照顾细节',
              date: '08.12',
              icon: Icons.light_mode_outlined,
              color: feltClay,
              iconSurfaceAsset: materialClayAsset,
              onTap: () => openDetail(context, '记录详情', const CardDetail()),
            );
            if (narrow) {
              return Column(
                children: [
                  SizedBox(height: 248, child: first),
                  const SizedBox(height: 14),
                  SizedBox(height: 248, child: second),
                ],
              );
            }
            return SizedBox(
              height: 248,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: 12),
                  Expanded(child: second),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        AssetFeltSurface(
          color: feltIvory,
          surfaceAsset: materialIvoryAsset,
          textureOpacity: .72,
          radius: 22,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GROWTH CALENDAR',
                style: TextStyle(
                  color: feltMuted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '2026 年 8 月',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_left, size: 19),
                  const Text('月历', style: TextStyle(fontSize: 12)),
                  const Icon(Icons.chevron_right, size: 19),
                ],
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('日'),
                  Text('一'),
                  Text('二'),
                  Text('三'),
                  Text('四'),
                  Text('五'),
                  Text('六'),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 37,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: .94,
                ),
                itemBuilder: (_, i) {
                  final day = i - 5;
                  final marked = [3, 12, 19, 27].contains(day);
                  if (day <= 0 || day > 31) return const SizedBox.shrink();
                  if (!marked) {
                    return Center(
                      child: Text('$day', style: const TextStyle(fontSize: 12)),
                    );
                  }
                  final clay = day == 12;
                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: AssetFeltSurface(
                      color: clay ? feltClay : feltSage,
                      surfaceAsset: clay
                          ? materialClayAsset
                          : materialSageAsset,
                      textureOpacity: .86,
                      radius: 9,
                      depth: 1,
                      padding: EdgeInsets.zero,
                      showHighlightBorder: false,
                      child: Center(
                        child: Text(
                          '$day',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: AssetFeltSurface(
            color: feltForest,
            surfaceAsset: materialForestAsset,
            radius: 18,
            depth: 2,
            padding: EdgeInsets.zero,
            onTap: () => openDetail(context, '八月回望', const MonthlyDetail()),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph, color: feltIvory, size: 20),
                  SizedBox(width: 9),
                  Text(
                    '查看月度总结',
                    style: TextStyle(
                      color: feltIvory,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class RecordCard extends StatelessWidget {
  final String title, date;
  final IconData icon;
  final Color color;
  final String iconSurfaceAsset;
  final VoidCallback onTap;
  const RecordCard({
    super.key,
    required this.title,
    required this.date,
    required this.icon,
    required this.color,
    required this.iconSurfaceAsset,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .76,
      radius: 22,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: Image.asset(
                    materialLandscapeAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: AssetFeltIconTile(
                    icon: icon,
                    color: color,
                    surfaceAsset: iconSurfaceAsset,
                    size: 42,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: feltMuted,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: feltInk,
                        fontFamily: 'NotoSerifSC',
                        fontSize: 16,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '打开回顾',
                          style: TextStyle(
                            color: feltForest,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.chevron_right, size: 16, color: feltForest),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PortraitPage extends StatelessWidget {
  const PortraitPage({super.key});
  @override
  Widget build(BuildContext context) {
    final skills = <(String, String, IconData, Color, String)>[
      ('观察力', '感知', Icons.eco_outlined, feltSage, materialSageAsset),
      ('整理', '组织', Icons.filter_alt_outlined, feltClay, materialClayAsset),
      ('持续照护', '实践', Icons.water_drop_outlined, feltBlue, materialBlueAsset),
      ('审美判断', '创造', Icons.balance_outlined, feltMustard, materialMustardAsset),
      ('经验表达', '沟通', Icons.menu_book_outlined, feltIvory, materialIvoryAsset),
      ('分类能力', '梳理', Icons.extension_outlined, feltBlue, materialBlueAsset),
      ('耐心', '支撑', Icons.favorite_border, feltClay, materialClayAsset),
      ('共情', '关系', Icons.people_outline, feltSage, materialSageAsset),
      ('空间感', '想象', Icons.architecture_outlined, feltIvory, materialIvoryAsset),
      ('问题拆解', '思考', Icons.forum_outlined, feltMustard, materialMustardAsset),
    ];
    Widget skill(int i) {
      final s = skills[i];
      return MaterialSkillTile(
        label: s.$1,
        caption: s.$2,
        icon: s.$3,
        color: s.$4,
        surfaceAsset: s.$5,
        onTap: () => openDetail(context, '能力说明', SkillDetail(skill: s.$1)),
      );
    }

    Widget skillRow(List<int> indexes, {bool inset = false}) => Padding(
      padding: EdgeInsets.symmetric(horizontal: inset ? 24 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < indexes.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: skill(indexes[i])),
          ],
        ],
      ),
    );

    return AssetMaterialBackdrop(
      child: PageFrame(
        eyebrow: 'PERSONAL FIELD · 027',
        title: '我的画像',
        subtitle: '由你的对话、行动记录和真实选择慢慢形成。每一条判断都可以回到具体证据。',
        children: [
          const SizedBox(height: 10),
          AssetFeltSurface(
            color: feltIvory,
            surfaceAsset: materialIvoryAsset,
            textureOpacity: .72,
            radius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AssetFeltIconTile(
                      icon: Icons.person_outline,
                      color: feltClay,
                      surfaceAsset: materialClayAsset,
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '林溪',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'MY PORTRAIT',
                            style: TextStyle(
                              color: feltMuted,
                              letterSpacing: 1.5,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('我的画像', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 9),
                const Text('每一条判断都可以回到具体证据，也可以由你修改。'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AssetFeltSurface(
            color: feltIvory,
            surfaceAsset: materialIvoryAsset,
            textureOpacity: .66,
            radius: 22,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'SKILL FIELD / 24 SIGNALS',
                  style: TextStyle(
                    color: feltMuted,
                    letterSpacing: 1.4,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已发现的能力线索',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                skillRow([0, 1, 2]),
                const SizedBox(height: 16),
                skillRow([3, 4], inset: true),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 104,
                    width: double.infinity,
                    child: Image.asset(
                      materialLandscapeAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                skillRow([5, 6], inset: true),
                const SizedBox(height: 16),
                skillRow([7, 8, 9]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PortraitMenuCard(
            icon: Icons.menu_book_outlined,
            title: '全部能力词库',
            subtitle: '查看能力分类与成长证据',
            onTap: () => openDetail(context, '能力词库', const VocabularyDetail()),
          ),
          PortraitMenuCard(
            icon: Icons.auto_stories_outlined,
            title: '个人档案与记忆',
            subtitle: '23 条记录',
            onTap: () => openDetail(context, '记忆管理', const MemoryDetail()),
          ),
          PortraitMenuCard(
            icon: Icons.shield_outlined,
            title: '数据与摄像头权限',
            subtitle: '由你控制',
            onTap: () => openDetail(context, '数据与权限', const PrivacyContent()),
          ),
          PortraitMenuCard(
            icon: Icons.ios_share_outlined,
            title: '导出我的内容',
            subtitle: '生成个人数据副本',
            onTap: () => openDetail(context, '导出我的内容', const ExportDetail()),
          ),
        ],
      ),
    );
  }
}

class MaterialSkillTile extends StatelessWidget {
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final String surfaceAsset;
  final VoidCallback onTap;

  const MaterialSkillTile({
    super.key,
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final iconSize = box.maxWidth.clamp(50.0, 62.0).toDouble();
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AssetFeltIconTile(
              icon: icon,
              color: color,
              surfaceAsset: surfaceAsset,
              size: iconSize,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              caption,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: feltMuted),
            ),
          ],
        ),
      );
    },
  );
}

class PortraitMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const PortraitMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .54,
      radius: 17,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      onTap: onTap,
      child: Row(
        children: [
          AssetFeltIconTile(
            icon: icon,
            color: feltSage,
            surfaceAsset: materialSageAsset,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: feltMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    ),
  );
}

class PartnersPage extends StatelessWidget {
  const PartnersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final partners = <(String, String, String, Color, String)>[
      ('周宁', '内容运营', '92%', feltSage, materialSageAsset),
      ('阿禾', '社区组织', '86%', feltClay, materialClayAsset),
      ('Mia', '摄影记录', '78%', feltBlue, materialBlueAsset),
    ];

    return AssetMaterialBackdrop(
      child: PageFrame(
        eyebrow: 'MY SOCIAL FIELD',
        title: '我的同路人',
        subtitle: '从兴趣与能力出发，发现可以一起尝试小项目的人。',
        children: [
          const SizedBox(height: 10),
          AssetFeltSurface(
            color: feltIvory,
            surfaceAsset: materialIvoryAsset,
            textureOpacity: .72,
            radius: 22,
            padding: EdgeInsets.zero,
            onTap: () =>
                openDetail(context, '可探索的方向', const OpportunityDetail()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'MY SOCIAL CARD · 01',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 10,
                                color: feltMuted,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '上海 · 可线上交流',
                            style: TextStyle(fontSize: 10, color: feltMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const AssetFeltIconTile(
                            icon: Icons.person_outline,
                            color: feltSage,
                            surfaceAsset: materialSageAsset,
                            size: 66,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '林溪',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '喜欢植物、整理和记录生活。',
                                  style: TextStyle(fontSize: 12, height: 1.45),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 14),
                      const Text(
                        '感兴趣',
                        style: TextStyle(color: feltMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '社区分享与新手陪伴',
                        style: TextStyle(
                          color: pine,
                          fontFamily: 'NotoSerifSC',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '想认识同样关心植物和日常生活的人，一起交换真实经验。',
                        style: TextStyle(fontSize: 11, height: 1.5),
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 14),
                      const Text(
                        '擅长',
                        style: TextStyle(color: feltMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '观察细节、分类整理、持续照护',
                        style: TextStyle(
                          color: pine,
                          fontFamily: 'NotoSerifSC',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '能从零散信息里发现差异，并整理成可以长期使用的方法。',
                        style: TextStyle(fontSize: 11, height: 1.5),
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        '个人资料确认仅在你确认后展示',
                        style: TextStyle(fontSize: 10.5, color: feltMuted),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              '点击名片，查看探索方向',
                              style: TextStyle(
                                color: pine,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.north_east, color: pine, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 112,
                  width: double.infinity,
                  child: Image.asset(
                    materialLandscapeAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('可以认识的人', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text(
            '匹配度只是一条线索，你可以先看合作设想，再决定是否交流。',
            style: TextStyle(fontSize: 11.5, color: feltMuted, height: 1.5),
          ),
          const SizedBox(height: 14),
          for (final partner in partners)
            PartnerSuggestionCard(
              name: partner.$1,
              role: partner.$2,
              match: partner.$3,
              color: partner.$4,
              surfaceAsset: partner.$5,
              onTap: () =>
                  openDetail(context, '伙伴空间', PartnerDetail(name: partner.$1)),
            ),
        ],
      ),
    );
  }
}

class PartnerSuggestionCard extends StatelessWidget {
  final String name;
  final String role;
  final String match;
  final Color color;
  final String surfaceAsset;
  final VoidCallback onTap;

  const PartnerSuggestionCard({
    super.key,
    required this.name,
    required this.role,
    required this.match,
    required this.color,
    required this.surfaceAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .58,
      radius: 18,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      onTap: onTap,
      child: Row(
        children: [
          AssetFeltIconTile(
            icon: Icons.person_outline,
            color: color,
            surfaceAsset: surfaceAsset,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifSC',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$role · 查看合作设想',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: feltMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            match,
            style: const TextStyle(
              color: pine,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right, size: 19),
        ],
      ),
    ),
  );
}

void openDetail(BuildContext context, String title, Widget child) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScaffold(title: title, child: child),
      ),
    );

class DetailScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const DetailScaffold({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
    ),
    body: FeltBackdrop(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class CardDetail extends StatelessWidget {
  const CardDetail({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '08.19  ·  整理与空间',
        style: TextStyle(color: feltMuted, fontSize: 11, letterSpacing: .4),
      ),
      const SizedBox(height: 7),
      Text('让杂乱重新有秩序', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 18),
      const AssetFeltSurface(
        color: feltIvory,
        surfaceAsset: materialIvoryAsset,
        textureOpacity: .74,
        radius: 22,
        padding: EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“',
              style: TextStyle(
                color: feltSage,
                fontFamily: 'NotoSerifSC',
                fontSize: 40,
                height: .7,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '我把阳台重新整理了一下，\n还给每盆植物做了标签。',
              style: TextStyle(
                color: feltInk,
                fontFamily: 'NotoSerifSC',
                fontSize: 20,
                height: 1.65,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Text('这张记录看见了什么', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 14),
      const EvidenceLine(
        number: '01',
        title: '先观察差异',
        description: '发现不同植物需要不同的光照和照护方式。',
        icon: Icons.eco_outlined,
        color: feltSage,
        surfaceAsset: materialSageAsset,
      ),
      const EvidenceLine(
        number: '02',
        title: '建立分类方法',
        description: '为每盆植物制作标签，把零散信息整理清楚。',
        icon: Icons.filter_alt_outlined,
        color: feltBlue,
        surfaceAsset: materialBlueAsset,
      ),
      const EvidenceLine(
        number: '03',
        title: '让结果可以延续',
        description: '空间更容易维护，方法也可以继续使用。',
        icon: Icons.light_mode_outlined,
        color: feltMustard,
        surfaceAsset: materialMustardAsset,
      ),
      const SizedBox(height: 8),
      AssetFeltSurface(
        color: feltBlue,
        surfaceAsset: materialBlueAsset,
        textureOpacity: .78,
        radius: 19,
        depth: 2,
        padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
        child: const Row(
          children: [
            AssetFeltIconTile(
              icon: Icons.link,
              color: feltIvory,
              surfaceAsset: materialIvoryAsset,
              size: 42,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '查看相关证据',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '2 条记录与 1 次行动',
                    style: TextStyle(fontSize: 11, color: feltMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: () {}, child: const Text('准确')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(onPressed: () {}, child: const Text('修正')),
          ),
        ],
      ),
    ],
  );
}

class EvidenceLine extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String surfaceAsset;

  const EvidenceLine({
    super.key,
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .54,
      radius: 18,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 12, 11, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetFeltIconTile(
            icon: icon,
            color: color,
            surfaceAsset: surfaceAsset,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        color: pine,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: feltMuted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MonthlyDetail extends StatelessWidget {
  const MonthlyDetail({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'AUGUST REVIEW · 2026',
        style: TextStyle(
          color: pine,
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text('八月，\n你更认识自己了一点', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 10),
      const Text(
        '你持续通过观察、分类与记录，让复杂的日常变得更容易理解。',
        style: TextStyle(color: feltMuted, height: 1.55),
      ),
      const SizedBox(height: 18),
      AssetFeltSurface(
        color: feltIvory,
        surfaceAsset: materialIvoryAsset,
        textureOpacity: .62,
        radius: 22,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              materialLandscapeAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('本月形成的能力轮廓', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 13),
      const MonthlyAbilityCard(
        title: '协调力',
        description: '在不同需要之间找到平衡，让事情继续向前。',
        evidenceCount: '6 条依据',
        value: .86,
        icon: Icons.eco_outlined,
        color: feltSage,
        surfaceAsset: materialSageAsset,
      ),
      const MonthlyAbilityCard(
        title: '观察力',
        description: '先看见细节和差异，再决定怎样行动。',
        evidenceCount: '5 条依据',
        value: .72,
        icon: Icons.waves_outlined,
        color: feltBlue,
        surfaceAsset: materialBlueAsset,
      ),
      const MonthlyAbilityCard(
        title: '持续照护',
        description: '把一次行动变成可以长期维持的方法。',
        evidenceCount: '3 条依据',
        value: .58,
        icon: Icons.light_mode_outlined,
        color: feltMustard,
        surfaceAsset: materialMustardAsset,
      ),
      const SizedBox(height: 8),
      const AssetFeltSurface(
        color: feltIvory,
        surfaceAsset: materialIvoryAsset,
        textureOpacity: .68,
        radius: 19,
        padding: EdgeInsets.fromLTRB(17, 16, 17, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '下个月可以继续留意',
              style: TextStyle(
                color: pine,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 7),
            Text(
              '当你把照顾经验讲给别人听时，“整理”可能会进一步转化成教学和内容表达。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 54,
        width: double.infinity,
        child: AssetFeltSurface(
          color: feltForest,
          surfaceAsset: materialForestAsset,
          radius: 17,
          depth: 2,
          padding: EdgeInsets.zero,
          onTap: () {},
          child: const Center(
            child: Text(
              '查看这一月',
              style: TextStyle(
                color: feltIvory,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class MonthlyAbilityCard extends StatelessWidget {
  final String title;
  final String description;
  final String evidenceCount;
  final double value;
  final IconData icon;
  final Color color;
  final String surfaceAsset;

  const MonthlyAbilityCard({
    super.key,
    required this.title,
    required this.description,
    required this.evidenceCount,
    required this.value,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .58,
      radius: 18,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      child: Column(
        children: [
          Row(
            children: [
              AssetFeltIconTile(
                icon: icon,
                color: color,
                surfaceAsset: surfaceAsset,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'NotoSerifSC',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          evidenceCount,
                          style: const TextStyle(
                            color: pine,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: feltMuted,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              color: color,
              backgroundColor: feltLine,
            ),
          ),
        ],
      ),
    ),
  );
}

class ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  const ProgressLine({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: value,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: pine,
          backgroundColor: line,
        ),
      ],
    ),
  );
}

class SkillDetail extends StatelessWidget {
  final String skill;
  const SkillDetail({super.key, required this.skill});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AssetFeltSurface(
        color: feltSage,
        surfaceAsset: materialSageAsset,
        textureOpacity: .78,
        radius: 22,
        padding: const EdgeInsets.fromLTRB(17, 17, 16, 18),
        child: Row(
          children: [
            const AssetFeltIconTile(
              icon: Icons.eco_outlined,
              color: feltIvory,
              surfaceAsset: materialIvoryAsset,
              size: 56,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill,
                    style: const TextStyle(
                      color: feltInk,
                      fontFamily: 'NotoSerifSC',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '置信度 94%',
                    style: TextStyle(fontSize: 11, color: feltMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '“',
              style: TextStyle(
                color: feltClay,
                fontFamily: 'NotoSerifSC',
                fontSize: 38,
                height: .8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '你倾向于先理解差异，\n再建立可以持续使用的方法。',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(height: 1.65, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const SkillSectionCard(
        title: '典型表现',
        expanded: true,
        lines: ['能从现象中分辨出不同，提出有用的问题。', '习惯先收集细节，再归纳规律。', '信息不完整时，也能给出合理判断。'],
      ),
      const SkillSectionCard(title: '适用场景'),
      const SkillSectionCard(title: '边界与待验证'),
      const SizedBox(height: 5),
      AssetFeltSurface(
        color: feltBlue,
        surfaceAsset: materialBlueAsset,
        textureOpacity: .78,
        radius: 18,
        depth: 2,
        padding: const EdgeInsets.fromLTRB(13, 13, 11, 13),
        child: Column(
          children: [
            Row(
              children: [
                const AssetFeltIconTile(
                  icon: Icons.folder_open_outlined,
                  color: feltIvory,
                  surfaceAsset: materialIvoryAsset,
                  size: 42,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '证据索引',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '2 条原始记录',
                        style: TextStyle(fontSize: 11, color: feltMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '查看',
                  style: TextStyle(
                    color: pine,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: () {}, child: const Text('准确')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(onPressed: () {}, child: const Text('修正')),
          ),
        ],
      ),
    ],
  );
}

class SkillSectionCard extends StatelessWidget {
  final String title;
  final bool expanded;
  final List<String> lines;

  const SkillSectionCard({
    super.key,
    required this.title,
    this.expanded = false,
    this.lines = const [],
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .56,
      radius: 18,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: feltSage,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 9),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(radius: 2, backgroundColor: pine),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(fontSize: 11, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class VocabularyDetail extends StatelessWidget {
  const VocabularyDetail({super.key});
  @override
  Widget build(BuildContext context) {
    final abilities = <(String, String, String, IconData, Color, String)>[
      ('观察力', '感知', '94%', Icons.eco_outlined, feltSage, materialSageAsset),
      (
        '整理',
        '组织',
        '91%',
        Icons.filter_alt_outlined,
        feltClay,
        materialClayAsset,
      ),
      (
        '持续照护',
        '关系',
        '89%',
        Icons.water_drop_outlined,
        feltBlue,
        materialBlueAsset,
      ),
      (
        '审美判断',
        '创造',
        '82%',
        Icons.balance_outlined,
        feltMustard,
        materialMustardAsset,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('能力词库', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        const Text(
          '每个词都能回到具体记录，也可以由你修改。',
          style: TextStyle(color: feltMuted, height: 1.5),
        ),
        const SizedBox(height: 18),
        const VocabularyFilterBar(),
        const SizedBox(height: 16),
        for (final ability in abilities)
          VocabularyAbilityCard(
            title: ability.$1,
            category: ability.$2,
            confidence: ability.$3,
            icon: ability.$4,
            color: ability.$5,
            surfaceAsset: ability.$6,
            onTap: () =>
                openDetail(context, '能力说明', SkillDetail(skill: ability.$1)),
          ),
      ],
    );
  }
}

class VocabularyFilterBar extends StatelessWidget {
  const VocabularyFilterBar({super.key});

  @override
  Widget build(BuildContext context) => AssetFeltSurface(
    color: feltIvory,
    surfaceAsset: materialIvoryAsset,
    textureOpacity: .5,
    radius: 17,
    depth: 1.5,
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    child: const Row(
      children: [
        Expanded(child: VocabularyFilterLabel(label: '全部', selected: true)),
        Expanded(child: VocabularyFilterLabel(label: '感知')),
        Expanded(child: VocabularyFilterLabel(label: '组织')),
        Expanded(child: VocabularyFilterLabel(label: '更多')),
      ],
    ),
  );
}

class VocabularyFilterLabel extends StatelessWidget {
  final String label;
  final bool selected;

  const VocabularyFilterLabel({
    super.key,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: selected ? pine : feltMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: selected ? 24 : 0,
          height: 2,
          decoration: BoxDecoration(
            color: pine,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

class VocabularyAbilityCard extends StatelessWidget {
  final String title;
  final String category;
  final String confidence;
  final IconData icon;
  final Color color;
  final String surfaceAsset;
  final VoidCallback onTap;

  const VocabularyAbilityCard({
    super.key,
    required this.title,
    required this.category,
    required this.confidence,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .58,
      radius: 19,
      depth: 2,
      padding: const EdgeInsets.fromLTRB(13, 13, 10, 13),
      onTap: onTap,
      child: Row(
        children: [
          AssetFeltIconTile(
            icon: icon,
            color: color,
            surfaceAsset: surfaceAsset,
            size: 54,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifSC',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category,
                  style: const TextStyle(fontSize: 11, color: feltMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '置信度',
                style: TextStyle(fontSize: 9.5, color: feltMuted),
              ),
              const SizedBox(height: 2),
              Text(
                confidence,
                style: const TextStyle(
                  color: pine,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    ),
  );
}

class MemoryDetail extends StatelessWidget {
  const MemoryDetail({super.key});
  @override
  Widget build(BuildContext context) {
    final records = <(String, String, String, IconData, Color, String)>[
      (
        '8月12日',
        '怎么把照顾经验分享出去',
        '对话',
        Icons.forum_outlined,
        feltSage,
        materialSageAsset,
      ),
      (
        '8月3日',
        '我看见了自己的协调力',
        '卡片',
        Icons.bookmark_outline,
        feltClay,
        materialClayAsset,
      ),
      (
        '7月29日',
        '我是不是也有审美能力',
        '对话',
        Icons.forum_outlined,
        feltBlue,
        materialBlueAsset,
      ),
      (
        '7月15日',
        '家庭里的工作算不算创造',
        '对话',
        Icons.forum_outlined,
        feltMustard,
        materialMustardAsset,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('记忆管理', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        const Text(
          '由你决定哪些内容被保留。每条记忆都可以查看，也可以删除。',
          style: TextStyle(color: feltMuted, height: 1.5),
        ),
        const SizedBox(height: 18),
        const MemoryFilterBar(),
        const SizedBox(height: 16),
        for (final record in records)
          MemoryRecordCard(
            date: record.$1,
            title: record.$2,
            type: record.$3,
            icon: record.$4,
            color: record.$5,
            surfaceAsset: record.$6,
            onTap: () => openDetail(context, '记录详情', const CardDetail()),
          ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            '共 23 条记忆',
            style: TextStyle(fontSize: 12, color: feltMuted),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB54E3D),
            ),
            child: const Text('删除全部记忆'),
          ),
        ),
      ],
    );
  }
}

class MemoryFilterBar extends StatelessWidget {
  const MemoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) => AssetFeltSurface(
    color: feltIvory,
    surfaceAsset: materialIvoryAsset,
    textureOpacity: .5,
    radius: 17,
    depth: 1.5,
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    child: const Row(
      children: [
        Expanded(child: VocabularyFilterLabel(label: '全部', selected: true)),
        Expanded(child: VocabularyFilterLabel(label: '对话')),
        Expanded(child: VocabularyFilterLabel(label: '卡片')),
      ],
    ),
  );
}

class MemoryRecordCard extends StatelessWidget {
  final String date;
  final String title;
  final String type;
  final IconData icon;
  final Color color;
  final String surfaceAsset;
  final VoidCallback onTap;

  const MemoryRecordCard({
    super.key,
    required this.date,
    required this.title,
    required this.type,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .56,
      radius: 18,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 11, 9, 11),
      onTap: onTap,
      child: Row(
        children: [
          AssetFeltIconTile(
            icon: icon,
            color: color,
            surfaceAsset: surfaceAsset,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontSize: 10, color: feltMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifSC',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            type,
            style: const TextStyle(
              color: pine,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, size: 19),
        ],
      ),
    ),
  );
}

class PrivacyContent extends StatefulWidget {
  const PrivacyContent({super.key});

  @override
  State<PrivacyContent> createState() => _PrivacyContentState();
}

class _PrivacyContentState extends State<PrivacyContent> {
  bool voiceInput = true;
  bool expressionCamera = false;
  bool longMemory = true;
  bool anonymousImprove = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('数据与权限', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 7),
      const Text(
        '由你主动决定。关闭后，对应能力不会继续读取或记录。',
        style: TextStyle(color: feltMuted, height: 1.5),
      ),
      const SizedBox(height: 20),
      PermissionRowCard(
        title: '语音输入',
        subtitle: '使用语音提问与记录',
        icon: Icons.mic_none_outlined,
        color: feltSage,
        surfaceAsset: materialSageAsset,
        value: voiceInput,
        onChanged: (value) => setState(() => voiceInput = value),
      ),
      PermissionRowCard(
        title: '表情与摄像头辅助',
        subtitle: '默认关闭，仅在你主动允许后使用',
        icon: Icons.camera_alt_outlined,
        color: feltClay,
        surfaceAsset: materialClayAsset,
        value: expressionCamera,
        onChanged: (value) => setState(() => expressionCamera = value),
      ),
      PermissionRowCard(
        title: '长期记忆',
        subtitle: '让对话记得你的偏好',
        icon: Icons.cloud_outlined,
        color: feltBlue,
        surfaceAsset: materialBlueAsset,
        value: longMemory,
        onChanged: (value) => setState(() => longMemory = value),
      ),
      PermissionRowCard(
        title: '匿名改进',
        subtitle: '帮助我们改进“我是谁”',
        icon: Icons.waves_outlined,
        color: feltMustard,
        surfaceAsset: materialMustardAsset,
        value: anonymousImprove,
        onChanged: (value) => setState(() => anonymousImprove = value),
      ),
      const SizedBox(height: 7),
      const AssetFeltSurface(
        color: feltBlue,
        surfaceAsset: materialBlueAsset,
        textureOpacity: .72,
        radius: 18,
        depth: 1.5,
        padding: EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssetFeltIconTile(
              icon: Icons.lock_outline,
              color: feltIvory,
              surfaceAsset: materialIvoryAsset,
              size: 40,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '所有设置仅在你选择后生效。你可以随时回来修改。',
                style: TextStyle(fontSize: 11.5, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFB54E3D)),
          child: const Text('删除本机全部数据'),
        ),
      ),
    ],
  );
}

class PermissionRowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String surfaceAsset;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PermissionRowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .56,
      radius: 19,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          AssetFeltIconTile(
            icon: icon,
            color: color,
            surfaceAsset: surfaceAsset,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifSC',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: feltMuted,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

class ExportDetail extends StatefulWidget {
  const ExportDetail({super.key});

  @override
  State<ExportDetail> createState() => _ExportDetailState();
}

class _ExportDetailState extends State<ExportDetail> {
  bool hideName = true;
  bool hideExactTime = false;
  bool confirmedOnly = true;
  bool exportAsImage = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('导出预览', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 7),
      const Text(
        '先确认公开范围，再生成只属于你的内容副本。',
        style: TextStyle(color: feltMuted, height: 1.5),
      ),
      const SizedBox(height: 17),
      const AssetFeltSurface(
        color: feltIvory,
        surfaceAsset: materialLandscapeAsset,
        surfaceAlignment: Alignment.center,
        textureOpacity: 1,
        radius: 20,
        depth: 2,
        padding: EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              Positioned(
                left: -22,
                right: -22,
                top: -20,
                height: 158,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF7F1E8),
                        Color(0xEAF7F1E8),
                        Color(0x00F7F1E8),
                      ],
                      stops: [0, .75, 1],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '我的成长记录',
                    style: TextStyle(
                      fontFamily: 'NotoSerifSC',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 11),
                  Text(
                    '我看见了自己的协调力\n我在照顾中学会了放手\n我值得被好好对待',
                    style: TextStyle(fontSize: 12, height: 1.65),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),
      ExportToggleRow(
        label: '隐藏姓名',
        value: hideName,
        accent: feltSage,
        onChanged: (value) => setState(() => hideName = value),
      ),
      ExportToggleRow(
        label: '隐藏具体时间',
        value: hideExactTime,
        accent: feltBlue,
        onChanged: (value) => setState(() => hideExactTime = value),
      ),
      ExportToggleRow(
        label: '仅导出已确认内容',
        value: confirmedOnly,
        accent: feltMustard,
        onChanged: (value) => setState(() => confirmedOnly = value),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          const Text(
            '格式',
            style: TextStyle(
              fontFamily: 'NotoSerifSC',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('图片')),
                ButtonSegment(value: false, label: Text('PDF')),
              ],
              selected: {exportAsImage},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => exportAsImage = selection.first),
            ),
          ),
        ],
      ),
      const SizedBox(height: 17),
      AssetFeltSurface(
        color: feltForest,
        surfaceAsset: materialForestAsset,
        textureOpacity: .92,
        radius: 17,
        depth: 2,
        padding: EdgeInsets.zero,
        onTap: () {},
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              exportAsImage ? '导出到相册' : '生成 PDF',
              style: const TextStyle(
                color: feltIvory,
                fontFamily: 'NotoSerifSC',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    ],
  );
}

class ExportToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const ExportToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 53,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: accent, width: 1.2)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'NotoSerifSC',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class OpportunityDetail extends StatelessWidget {
  const OpportunityDetail({super.key});
  @override
  Widget build(BuildContext context) {
    final opportunities = <(String, String, IconData, Color, String)>[
      (
        '植物照护 × 内容记录',
        '把照护经验整理成新手也能使用的小指南。',
        Icons.local_florist_outlined,
        feltSage,
        materialSageAsset,
      ),
      (
        '社区植物互助',
        '从交换养护经验开始，认识附近的同路人。',
        Icons.people_outline,
        feltClay,
        materialClayAsset,
      ),
      (
        '新手七日陪伴',
        '用观察、整理和持续照护，设计一段轻量陪伴。',
        Icons.calendar_today_outlined,
        feltBlue,
        materialBlueAsset,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('一起能做什么', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        const Text(
          '这些方向来自你已经确认的兴趣与能力，可以先从一件小事试起。',
          style: TextStyle(color: feltMuted, height: 1.5),
        ),
        const SizedBox(height: 18),
        const AssetFeltSurface(
          color: feltIvory,
          surfaceAsset: materialLandscapeAsset,
          textureOpacity: 1,
          radius: 21,
          depth: 2,
          padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: SizedBox(
            height: 138,
            child: Stack(
              children: [
                Positioned(
                  left: -20,
                  right: -20,
                  top: -18,
                  height: 150,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF7F1E8),
                          Color(0xF2F7F1E8),
                          Color(0x00F7F1E8),
                        ],
                        stops: [0, .84, 1],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '从一件小事开始',
                      style: TextStyle(
                        fontFamily: 'NotoSerifSC',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      '不急着定义长期关系，\n先完成一次轻量合作。',
                      style: TextStyle(fontSize: 12, height: 1.55),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 21),
        Text('适合你的方向', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (var i = 0; i < opportunities.length; i++)
          OpportunityMaterialCard(
            index: i + 1,
            title: opportunities[i].$1,
            subtitle: opportunities[i].$2,
            icon: opportunities[i].$3,
            color: opportunities[i].$4,
            surfaceAsset: opportunities[i].$5,
            onTap: () => openDetail(context, '同好伙伴推荐', const PartnersPage()),
          ),
      ],
    );
  }
}

class OpportunityMaterialCard extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String surfaceAsset;
  final VoidCallback onTap;

  const OpportunityMaterialCard({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surfaceAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .58,
      radius: 19,
      depth: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      onTap: onTap,
      child: Row(
        children: [
          AssetFeltIconTile(
            icon: icon,
            color: color,
            surfaceAsset: surfaceAsset,
            size: 52,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0$index',
                  style: const TextStyle(
                    color: feltMuted,
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifSC',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: feltMuted,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    ),
  );
}

class PartnerDetail extends StatelessWidget {
  final String name;
  const PartnerDetail({super.key, required this.name});
  @override
  Widget build(BuildContext context) {
    final profile = switch (name) {
      '阿禾' => ('社区组织', '86%', feltClay, materialClayAsset),
      'Mia' => ('摄影记录', '78%', feltBlue, materialBlueAsset),
      _ => ('内容运营', '92%', feltSage, materialSageAsset),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('和$name打个招呼', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        const Text(
          '先看共同点，再决定是否发出一条轻量邀请。',
          style: TextStyle(color: feltMuted, height: 1.5),
        ),
        const SizedBox(height: 18),
        AssetFeltSurface(
          color: feltIvory,
          surfaceAsset: materialIvoryAsset,
          textureOpacity: .64,
          radius: 21,
          depth: 2,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AssetFeltIconTile(
                icon: Icons.person_outline,
                color: profile.$3,
                surfaceAsset: profile.$4,
                size: 66,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.$1} · 匹配度 ${profile.$2}',
                      style: const TextStyle(color: feltMuted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '上海 · 可线上交流',
                      style: TextStyle(color: pine, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text('共同线索', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: PartnerClueCard(
                icon: Icons.local_florist_outlined,
                label: '共同兴趣',
                value: '植物照护',
                color: feltSage,
                surfaceAsset: materialSageAsset,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: PartnerClueCard(
                icon: Icons.auto_stories_outlined,
                label: '互补能力',
                value: '整理 × 内容',
                color: feltMustard,
                surfaceAsset: materialMustardAsset,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const AssetFeltSurface(
          color: feltIvory,
          surfaceAsset: materialClayAsset,
          textureOpacity: .46,
          radius: 19,
          depth: 1.5,
          padding: EdgeInsets.fromLTRB(17, 15, 17, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '可以一起试试',
                style: TextStyle(
                  color: feltInk,
                  fontFamily: 'NotoSerifSC',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                '做一本「阳台植物新手手册」，先写清目标、分工和第一周的小成果。',
                style: TextStyle(color: feltInk, fontSize: 12, height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const AssetFeltSurface(
          color: feltBlue,
          surfaceAsset: materialBlueAsset,
          textureOpacity: .68,
          radius: 18,
          depth: 1.5,
          padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              AssetFeltIconTile(
                icon: Icons.lock_outline,
                color: feltIvory,
                surfaceAsset: materialIvoryAsset,
                size: 40,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  '只有你主动发送后，对方才会看到这条消息。',
                  style: TextStyle(fontSize: 11, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        AssetFeltSurface(
          color: feltIvory,
          surfaceAsset: materialIvoryAsset,
          textureOpacity: .54,
          radius: 19,
          depth: 1.5,
          padding: const EdgeInsets.all(10),
          child: const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '输入想说的话…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 14),
        MaterialPrimaryButton(
          label: '发送消息',
          icon: Icons.send_outlined,
          onTap: () {},
        ),
      ],
    );
  }
}

class PartnerClueCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String surfaceAsset;

  const PartnerClueCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.surfaceAsset,
  });

  @override
  Widget build(BuildContext context) => AssetFeltSurface(
    color: feltIvory,
    surfaceAsset: materialIvoryAsset,
    textureOpacity: .56,
    radius: 18,
    depth: 1.5,
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssetFeltIconTile(
          icon: icon,
          color: color,
          surfaceAsset: surfaceAsset,
          size: 42,
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: feltMuted, fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'NotoSerifSC',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    child: AssetFeltSurface(
      color: feltIvory,
      surfaceAsset: materialIvoryAsset,
      textureOpacity: .72,
      radius: 24,
      depth: 2.5,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AssetFeltIconTile(
              icon: Icons.camera_alt_outlined,
              color: feltClay,
              surfaceAsset: materialClayAsset,
              size: 58,
            ),
          ),
          const SizedBox(height: 17),
          Text('开启表情辅助？', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 9),
          const Text(
            '仅在本次对话中分析表情信号。原始画面不会被保存或上传，你可以随时关闭。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 15),
          const AssetFeltSurface(
            color: feltBlue,
            surfaceAsset: materialBlueAsset,
            textureOpacity: .68,
            radius: 16,
            depth: 1,
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Icon(Icons.visibility_off_outlined, size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '默认关闭，仅在你明确允许后使用。',
                    style: TextStyle(fontSize: 10.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          MaterialPrimaryButton(
            label: '允许本次使用',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('暂不开启'),
          ),
        ],
      ),
    ),
  );
}
