/// Small formatting helpers for display.
library;

/// How amounts are anchored for display (user-selectable).
enum AnchorUnit {
  /// No anchoring — always full thousands (e.g. 15,000).
  full,

  /// Anchor to 千 / K at ≥ 1,000 (e.g. 15K).
  thousand,

  /// Anchor to 萬 at ≥ 10,000 (e.g. 1.5 萬).
  wan,
}

/// App-wide default anchor, kept in sync with the persisted setting by the
/// root widget so existing call sites pick it up without threading a param.
/// Individual calls (e.g. tests) may override via the `unit` argument.
AnchorUnit defaultAnchorUnit = AnchorUnit.full;

/// Formats integer [cents] as TWD under the active [unit] anchoring.
///
/// - [AnchorUnit.full]: full thousands (15,000).
/// - [AnchorUnit.thousand]: ≥1,000 → K (15K); below shows full.
/// - [AnchorUnit.wan]: ≥10,000 → 萬 (1.5 萬, space before 萬); below shows full.
///
/// Anchored values use one decimal place with a trailing ".0" trimmed.
String formatTwd(int cents, {AnchorUnit? unit}) {
  final u = unit ?? defaultAnchorUnit;
  final dollars = cents ~/ 100;
  final sign = dollars < 0 ? '-' : '';
  final abs = dollars.abs();
  switch (u) {
    case AnchorUnit.full:
      return 'NT\$ $sign${_thousands(abs)}';
    case AnchorUnit.thousand:
      if (abs < 1000) return 'NT\$ $sign${_thousands(abs)}';
      return 'NT\$ $sign${_unit(abs / 1000)}K';
    case AnchorUnit.wan:
      if (abs < 10000) return 'NT\$ $sign${_thousands(abs)}';
      return 'NT\$ $sign${_unit(abs / 10000)} 萬';
  }
}

/// Formats a TWD [dollars] amount (whole dollars, may be fractional).
///
/// Used for investment values where prices are dollar-denominated.
String formatTwdDouble(num dollars, {AnchorUnit? unit}) =>
    formatTwd((dollars * 100).round(), unit: unit);

/// Same as [formatTwd] but without the "NT$ " prefix, for inline algebra
/// captions (e.g. 收入 60,000 − 生活費 22,000).
String formatBare(int cents, {AnchorUnit? unit}) =>
    formatTwd(cents, unit: unit).replaceFirst(r'NT$ ', '');

/// Formats a signed percentage like "+10.7%" / "-4.5%".
String formatPercent(double ratio) {
  final pct = ratio * 100;
  final sign = pct >= 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(1)}%';
}

String _thousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// One decimal place (trailing ".0" trimmed), with the integer part grouped
/// in thousands so anchored values read cleanly (e.g. 1,234K, 15,000 萬).
String _unit(double v) {
  final oneDp = v.toStringAsFixed(1);
  final trimmed =
      oneDp.endsWith('.0') ? oneDp.substring(0, oneDp.length - 2) : oneDp;
  final dot = trimmed.indexOf('.');
  if (dot == -1) return _thousands(int.parse(trimmed));
  final intPart = _thousands(int.parse(trimmed.substring(0, dot)));
  return '$intPart${trimmed.substring(dot)}';
}
