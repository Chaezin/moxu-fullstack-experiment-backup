import 'package:flutter_test/flutter_test.dart';
import 'package:shiguang_app/voice/windows_web_assets.dart';

void main() {
  test('resolves bundled web directory beside the Windows executable', () {
    final result = windowsWebAssetRoot(
      r'C:\app\shiguang_app.exe',
    ).replaceAll('\\', '/');
    expect(result, 'C:/app/data/flutter_assets/assets/web/');
  });

  test('uses a stable secure virtual origin', () {
    expect(windowsWebOrigin, 'https://appassets.shiguang');
  });
}
