// LockController:啟用設 PIN、驗證、上鎖/解鎖、停用清除。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/lock_controller.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('enable 設 PIN → verify → lock/unlock → disable 清除', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final ctl = c.read(lockControllerProvider.notifier);

    await ctl.enable('1234');
    expect(c.read(lockControllerProvider).enabled, isTrue);
    expect(await ctl.verifyPin('1234'), isTrue);
    expect(await ctl.verifyPin('9999'), isFalse);

    ctl.lock();
    expect(c.read(lockControllerProvider).locked, isTrue);
    ctl.unlock();
    expect(c.read(lockControllerProvider).locked, isFalse);

    await ctl.disable();
    expect(c.read(lockControllerProvider).enabled, isFalse);
    expect(await ctl.verifyPin('1234'), isFalse); // PIN 已清除
  });

  test('停用時 lock() 不會上鎖', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(lockControllerProvider.notifier).lock();
    expect(c.read(lockControllerProvider).locked, isFalse);
  });
}
