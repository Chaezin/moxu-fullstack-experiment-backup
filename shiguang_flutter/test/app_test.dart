import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/main.dart';

void main() {
  testWidgets('shows the Shiguang login experience', (tester) async {
    await tester.pumpWidget(const ShiguangApp());
    expect(find.text('登录个人成长空间'), findsOneWidget);
    expect(find.text('拾光'), findsOneWidget);
  });
}
