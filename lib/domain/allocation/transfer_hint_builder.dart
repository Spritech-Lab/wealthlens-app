/// Builds transfer hints from an allocation result — pure Dart.
///
/// Because every wallet belongs to one account (INV-2), each non-zero
/// allocation maps to a concrete "請轉帳 X 元到 {帳戶}" instruction.
library;

/// A single transfer instruction for one wallet's allocation.
class TransferHint {
  /// Creates a [TransferHint].
  const TransferHint({
    required this.walletId,
    required this.accountName,
    required this.amount,
  });

  /// The wallet receiving the money.
  final String walletId;

  /// The destination account's display name.
  final String accountName;

  /// Amount to transfer, in cents.
  final int amount;

  /// User-facing instruction, e.g. "請轉帳 1,500 元到 永豐".
  String get message => '請轉帳 ${_formatDollars(amount)} 元到 $accountName';

  static String _formatDollars(int cents) {
    final dollars = cents ~/ 100;
    final remainder = cents % 100;
    final whole = _thousands(dollars);
    if (remainder == 0) return whole;
    return '$whole.${remainder.toString().padLeft(2, '0')}';
  }

  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Turns allocations into ordered transfer hints.
class TransferHintBuilder {
  /// Builds one hint per non-zero allocation.
  ///
  /// [accountNameOf] maps a wallet id to its owning account's display name.
  /// Wallets with a zero (or missing) allocation produce no hint.
  static List<TransferHint> build({
    required Map<String, int> allocations,
    required String Function(String walletId) accountNameOf,
  }) {
    final hints = <TransferHint>[];
    allocations.forEach((walletId, amount) {
      if (amount <= 0) return;
      hints.add(
        TransferHint(
          walletId: walletId,
          accountName: accountNameOf(walletId),
          amount: amount,
        ),
      );
    });
    return hints;
  }
}
