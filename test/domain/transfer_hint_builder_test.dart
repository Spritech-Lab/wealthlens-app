// TransferHintBuilder tests — maps allocations to "請轉帳 X 元到 {帳戶}".
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/domain/allocation/transfer_hint_builder.dart';

void main() {
  String nameOf(String walletId) => switch (walletId) {
        'w_travel' => '永豐',
        'w_emergency' => 'DAWHO',
        _ => '未知',
      };

  test('builds one hint per non-zero allocation', () {
    final hints = TransferHintBuilder.build(
      allocations: {'w_emergency': 100000, 'w_travel': 150000, 'w_zero': 0},
      accountNameOf: nameOf,
    );
    expect(hints.length, 2);
    expect(
      hints.map((h) => h.walletId),
      containsAll(['w_emergency', 'w_travel']),
    );
  });

  test('message formats dollars with thousands and account name', () {
    final hints = TransferHintBuilder.build(
      allocations: {'w_travel': 150000}, // 1,500.00
      accountNameOf: nameOf,
    );
    expect(hints.single.message, '請轉帳 1,500 元到 永豐');
  });

  test('message keeps cents when not whole dollars', () {
    final hints = TransferHintBuilder.build(
      allocations: {'w_emergency': 123456}, // 1,234.56
      accountNameOf: nameOf,
    );
    expect(hints.single.message, '請轉帳 1,234.56 元到 DAWHO');
  });

  test('zero and negative allocations produce no hint', () {
    final hints = TransferHintBuilder.build(
      allocations: {'a': 0, 'b': -10},
      accountNameOf: nameOf,
    );
    expect(hints, isEmpty);
  });
}
