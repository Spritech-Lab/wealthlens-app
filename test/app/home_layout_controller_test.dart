// HomeLayoutController:預設資訊卡、set 列表後更新。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/home_layout_controller.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('預設 cards,set(list) 後更新', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(homeLayoutControllerProvider), HomeLayout.cards);

    await c.read(homeLayoutControllerProvider.notifier).set(HomeLayout.list);
    expect(c.read(homeLayoutControllerProvider), HomeLayout.list);
  });
}
