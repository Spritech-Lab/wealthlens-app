// FontScaleController:預設標準、set 後更新、factor 對應正確。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/font_scale_controller.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('factor 對應(基準已上調,標準 = 1.15)', () {
    expect(FontScale.small.factor, 1.0);
    expect(FontScale.standard.factor, 1.15);
    expect(FontScale.large.factor, 1.3);
    expect(FontScale.xlarge.factor, 1.45);
  });

  test('預設標準,set 後更新', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(fontScaleControllerProvider), FontScale.standard);

    await c.read(fontScaleControllerProvider.notifier).set(FontScale.large);
    expect(c.read(fontScaleControllerProvider), FontScale.large);
  });
}
