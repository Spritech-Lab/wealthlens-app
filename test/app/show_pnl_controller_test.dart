// ShowPnlController:預設顯示、set false 後隱藏。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/show_pnl_controller.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('預設 true,set(show:false) 後更新', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(showPnlControllerProvider), isTrue);

    await c.read(showPnlControllerProvider.notifier).set(show: false);
    expect(c.read(showPnlControllerProvider), isFalse);
  });
}
