import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/main.dart';

void main() {
  test('WebView target remains stable', () {
    final target = Uri.parse(shiguangWebUrl);
    expect(target.host, 'a-d7g81pr41f2b54449-1475901646.tcloudbaseapp.com');
    expect(target.path, '/demo/');
  });
}
